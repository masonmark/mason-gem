
require 'pathname'
require 'tempfile'
require 'yaml'

module Mason

  # Derployer manages a collection of DerpVar instances ("derp vars"), which define values that control a deploy. The derp vars are themselves immutable, but they have values associated with them; those values have defaults and may be overridden individually or in groups. The derp vars are just definitions that determine things like default values, allowed values, and other metadata; the state pertaining to what value is associated with each derp var is maintained by the Derployer object.
  #
  # Basically there are three levels at which values are assigned to derp vars: 1.) each derp var has a default value, but 2.) that may be overridden by the currently active value list (i.e. named group of values, e.g. 'production', 'staging', etc), and 3.) those values in turn may be overridden by the user for a given deploy.

  class Derployer


    def initialize(name = nil, print_block: nil)

      @print_block = print_block
        # if non-nil, this will be used to print

      @name = name
        # names should be unique, e.g. 'deploy-mycoolapp'

      @active_value_list_identifier = nil
        # Only one value list can be "active".

      @value_definitions = {}
        # The list of DerpVar instances that define what deploy values exist.
        # {symbol (DerpVar identifier): DerpVar instance}

      @value_lists = {}
        # The named lists of values (e.g., :production, :staging, etc)
        # {symbol (id of vlist): {symbol (DerpVar identifier): string}}

      @value_overrides = {}
        # User-specified overrides (e.g. entered on command line)

      @tempfile_hospital = []
        # keeps tempfile instances from deallocing when var goes out of scope

    end


    # Returns the name of the Deployer instance, e.g. "deploy-rollerball". Returns "generic" if no name is set.
    def name
      @name || 'generic'
    end


    # Returns the path to the dir containing the script (as a Pathname)
    def path_to_root
      path_to_script = Pathname.new(File.expand_path $PROGRAM_NAME)
      path_to_parent = path_to_script.parent

      if path_to_parent.basename.to_s == 'bin'
        path_to_parent = path_to_parent.parent
      end
      path_to_parent
    end


    # The run() method is the main work method for a Derployer-based command-line tool.

    def run
      greet_user
      process_args
      confirm_settings
        # this will loop between confirm_settings <-> change_settings until user is done editing

      path_to_private_key    = write_ssh_key_to_temp_file
      path_to_inventory_file = write_ansible_inventory_file

      # instead of string formatting, make ∂ do it from objects

      playbook   = self[:ansible_playbook]

      # extra_vars = [:sysadmin_username, :server_type, :deploy_git_revision, :default_rails_env, :machine_type]
      extra_vars = @value_definitions.keys

      cmd = build_ansible_command inventory: path_to_inventory_file,
                             playbook: playbook,
                           extra_vars: extra_vars,
                              ssh_key: path_to_private_key

      settings_write

      begin_section("ATTEMPTING TO DEPLOY VIA ANSIBLE")
      print ''
      print cmd

      Kernel.system cmd

      if block_given?
        yield
      else
        # supplying a run block isn't required anymore; it can be useful with just default behavior
      end
    end


    def sysadmin_username
      return self[:sysadmin_username]
    end


    def infer_ssh_key_path
      path_to_root + 'ssh_keys' + "#{ self[:server_type] }.pem"
    end


    ######################### ANSIBLE #########################

    # Decrypt file with ansible vault and return contents (prompts user for password if necessary).
    def ansible_vault_read(path_to_encrypted_file, name: 'encrypted resource', password: nil)

      exit_status = 666
      while exit_status != 0
        # because ansible value may prompt

        password ||= ansible_vault_password_from_environment

        if password
          pw_file = write_temp_file(password)
          decrypted_contents = %x( ansible-vault --vault-password-file "#{ pw_file }" view "#{ path_to_encrypted_file }" )
        else
          decrypted_contents = %x( ansible-vault view "#{ path_to_encrypted_file }" )
        end

        exit_status = $?.exitstatus

        if exit_status != 0
          if password.nil?
            # means we are interactive, so show alert and try again until user cancels
            puts "⚠️ ️Unable to decrypt #{ name } at #{path_to_encrypted_file}. Please try again.\n\n"
          else
            break
          end
        end
      end

      decrypted_contents
    end

    # read DERPLOYER_ANSIBLE_VAULT_PASSWORD
    def ansible_vault_password_from_environment
      ENV['DERPLOYER_ANSIBLE_VAULT_PASSWORD']
    end

    # Write out simple single-host Ansible inventory to a temp file.
    def write_ansible_inventory_file

      server_type     = self[:server_type]
      target_host     = self[:target_host]
      target_ssh_port = self[:target_ssh_port]

      inventory_content =
        "[#{ server_type }]\n"                  \
        "deploy_target "                        \
        " ansible_ssh_host=#{ target_host }"    \
        " ansible_ssh_port=#{ target_ssh_port }"

      write_temp_file(inventory_content)
    end


    # Build the convoluted ansible-playbook command, with all the arguments and extra-vars.
    def build_ansible_command(inventory:, playbook:, extra_vars:, ssh_key:)

       extra_vars_str = '--extra-vars "'
       extra_vars.each { |k|
         extra_vars_str += "#{ k }='#{ self[k] }' " # note trailing space
       }
       extra_vars_str += '"'

       username = self[:sysadmin_username]
       playbook = self[:ansible_playbook]

      [
        "ansible-playbook ", # Mason 2016-03-15: you can add -vvvvv here to debug ansible troubles.
         "--inventory-file=#{ inventory }",
         "--user='#{ username }'",
         "--private-key='#{ ssh_key }'",
         "--ask-vault-pass",
         # "-vvvvv",
         extra_vars_str,
         playbook
       ].join " \\\n" # can't have whitespace after \ in shell
    end



    ######################### CLI #########################

    # Invokes the print_block, if one was supplied during initialization, otherwise just calls Kernel.print().
    def print(what, terminator: "\n")

      text = "#{what}#{terminator}"

      if @print_block
        return @print_block.call(text)
      else
        Kernel.print(text)
      end
    end


    # Returns a string containing the user input.
    def ask(q, strip: true, prompt: "> ", inputs: nil)

      inputs ||= FakeInput.new

      print q
      print prompt, terminator: nil

      fake = inputs.next
      if fake
        print fake
        answer = fake
      else
        answer = STDIN.gets
        answer.strip! if strip
      end

      answer
    end


    # Exit with fatal error message.
    def die(msg="unknown problem occurred")
      abort [
      "",
      "🐒",
      " ⌇",
      " 💩  DERP!! Um, whut: #{msg}",
      "",
      "",
       ].join("\n")
    end


    # Show introductory text.
    def greet_user

      path_to_tool = File.expand_path $PROGRAM_NAME

      begin_section "DErPLOYer: #{ name }"

      print ''
      print "(#{ path_to_tool })"
      print ""
      print "This tool can help provision a server and/or deploy an app."
      print "With no args, this script will use the last-used or default settings."
      print ""

    end


    # Kludge-process args
    def process_args

      # use slop you reject!! and self-bundle you trasher!

      if ARGV.include? 'reset'
        print "Resetting all settings to default."
        settings_write({})
      end

      vlist_identifiers = @value_lists.keys
      settings_names_from_args = vlist_identifiers.select { |identifier| ARGV.include? identifier.to_s }
      name_of_settings_to_load = settings_names_from_args.last
        # kludge: since we dont parse opts for real (yet), just use last valid value

      if ARGV.include? name_of_settings_to_load

        print "Initializing with settings for '#{ name_of_settings_to_load }'"
        activate_value_list name_of_settings_to_load.to_sym

      else
        previous_settings = settings_read
        if previous_settings.count > 0
          print "Initializing with last-used settings."

          previous_settings.each { |k,v|
            self.override k, v
          }


        else
          print "Initializing with default settings."
        end
      end
    end


    def begin_section(title)
      section_top = "\n"
      content  = "===== #{title} "
      needed   = (92 - content.length - 1)
      content += '=' * needed unless needed < 1

      print section_top + content
    end


    def print_menu(menu)

      return if menu.nil? || menu == {}

      longest_choice, _ = menu.max_by {|a| a[0].length}
      menu.each do |k,v|
        print "[#{k.rjust(longest_choice.to_i)}] ", terminator: nil
        print "#{v}"
      end
    end


    def edit_value(identifier, user_inputs: [])
      # Present UI to edit the value corresponding to identifier, and return the resulting value. (No side effects.)
      # The corresponding derp var determines what kind of UI is available (menu, direct entry, etc).
      #
      # identifier - string or symbol identifying the derp var to be edited
      # inputs - for testing, allows passing fake user input ('' means Return key without any text entry) to prevent interaction

      identifier    = identifier.to_sym
      inputs        = FakeInput.new user_inputs

      derp_var      = value_definition identifier
      predefined    = derp_var.predefined_values || []
      current_value = self[identifier]
      new_value     = 'error!!'
      other_values  = predefined.select {|e| e!= current_value}
      menu          = {}

      has_other_predefined_values = other_values.count > 0
      can_accept_manual_input     = !derp_var.enforce
      can_be_edited               = has_other_predefined_values || can_accept_manual_input

      begin_section "EDIT VALUE: #{identifier}"

      if ! can_be_edited

        print "\nDerrrp! can't edit #{identifier}: it is configured with only 1 valid value (#{current_value})"

      else

        if has_other_predefined_values

          derp_var.predefined_values.each_with_index do |value, index|
            num = index + 1
            menu["#{num}"] = "#{value}"
          end

          unless derp_var.enforce
            menu['i'] = 'Input new value directly'
          end
        end

        print ""

        has_menu = has_other_predefined_values

        if has_menu
          print_menu(menu)
          print ''
          print "Choose from menu, or press ↩︎ to accept current value: #{current_value}", terminator: nil
        else
          print "Enter new value, or press ↩︎ to accept current value: #{current_value}", terminator: nil
        end

        answer = ask "", inputs: inputs

        print ''

        if has_menu

          until answer == '' || menu.keys.include?(answer)
            print "Invalid answer (#{answer}). Please try again:", terminator: nil
            answer = ask "", inputs: inputs
            print ''
          end

          if answer ==  ''
            answer = nil

          elsif answer == 'i'
            print "Enter new value, or press ↩︎ to accept current value: #{current_value}", terminator: nil
            answer = ask '', inputs: inputs
            print ''

          else
            answer = menu[answer]
          end
        end
      end

      new_value = answer

      if new_value == '' && derp_var.allow_empty_string == false
        new_value = nil
      end

      new_value
    end


    def validate_user_input(setting, value)
      dv = value_definition setting
      dv.validate value
    end


    def confirm_settings(error_message=nil)

      begin_section "READY TO DEPLOY WITH THESE SETTINGS:"

      if error_message
        print ''
        print error_message
      end

      menu = {}

      active_values.each_with_index do |(k, v), i|
        menu_choice = (i + 1).to_s
        print "[#{menu_choice}] #{k}: #{v}"

        menu[menu_choice] = k

      end

      print ""

      answer = ask "Enter an item number to change, or Return to continue: "

      until answer == '' || menu.keys.include?(answer)
        print "YOU ARE AN INVALID PERSON"
        answer = ask ""
      end

      if answer != ''
        # hold on, the user wants to edit something...
        change_setting menu[answer]
      end
    end


    def change_setting(identifier, user_inputs: [])

      new_value = edit_value identifier, user_inputs: user_inputs

      if new_value.nil?

        print "Value of #{identifier} was not changed. It remains: #{self[identifier]}"

      else

        if validate_user_input(identifier, new_value)
          override identifier, new_value
          print "Value of #{identifier} changed to: #{new_value}"
        else
          #error_message = "WARNING: '#{new_setting}' is not an acceptable value for #{setting_name}; settings were not changed."
          print "WARNING: '#{new_setting}' is not an acceptable value for #{setting_name}; settings were not changed."
        end
      end

      return if user_inputs.count > 0 # because that means test mode

      confirm_settings
    end


    ######################### I/O #########################

    # Returns the settings path, which is partially based on the name, so if each deploy tool using this library uses a unique name, they don't clobber each other. Also, saved_settings_name allows saving an arbitary number of named lists of values.
    def settings_path(saved_settings_name = nil)
      name_segment = saved_settings_name ? "#{saved_settings_name}." : ""
      File.expand_path("~/.derployer-#{ name }.#{ name_segment }settings")
    end


    # Read the stored settings. A name value of nil means the read the default settings; any other value means read the settings stored under that name.
    def settings_read(name: nil)

      result = {}
      begin
        file_contents = IO.read settings_path(name)
        old_settings  = YAML.load file_contents
        if old_settings.class == Hash
          result = old_settings
        end
      rescue
        result = {}
      end

      result.select! {|k,v| value_definition(k) != nil }
      result
    end


    # Save settings. Supply a name value to save the settings as a distinct named list (and not interfere with default settings).
    def settings_write(settings_hash = active_values, name: nil)
      File.open settings_path(name), 'w' do |f|
        f.write settings_hash.to_yaml
      end
    end


    # Writes the ssh key to a temp file (so it can be passed as an arg to a command-line tool like ansible). The sole arg should be either the path to a key file, or nil to get default behavior, which will try to infer the path to the key based on conventions.
    def write_ssh_key_to_temp_file(src_file = nil)

      src_file ||= self[:override_ssh_key] || infer_ssh_key_path

      begin
        src_file_contents = IO.read File.expand_path(src_file)
      rescue => err
        die "can't read SSH key file: #{err}"
      end
      if src_file_contents.include? 'ANSIBLE_VAULT'
        src_file_contents = ansible_vault_read src_file
      end

      write_temp_file src_file_contents, prefix: 'private_key'
    end


    # Write a string to a secure tempfile and return the path to the file.
    def write_temp_file(contents, prefix: 'tempfile')
      t = Tempfile.new prefix
      t.write contents
      t.close

      @tempfile_hospital << t
        # Mason 2016-03-15: You MUST keep a ref to a Tempfile-created temp file around; if not, the file will be deleted when instance is GC'd. Caused shitty 30 min headache bug, where SSH connection failed because the key disappeared during connecting!

      FileUtils.chmod 0600, t.path # Mason 2016-03-15: may not be necessary (?), but doesn't hurt.

      t.path
    end


    ######################### VALUES #########################

    # Define a new deploy value. Conceptually, a deploy value is a value (currently only strings supported) with a unique name (expressed as a ruby symbol). For convenience, they define a bunch of metadata also, e.g. allowed values, info/help text, etc.
    def define(dict)
      raise "Can't define value without at least an identifier and intial value." unless dict.count > 0

      # ordered hash FTW
      identifier = dict.keys[0]

      predefined_values = dict.values[0]
      predefined_values = [predefined_values] unless predefined_values.is_a? Array

      dv = DerpVar.new identifier: identifier,
                       predefined_values: predefined_values,
                       info: dict[:info],
                       enforce: dict[:enforce] == true

      @value_definitions[dv.identifier] = dv
    end


    # Returns the derp var the defines the constraints for the value identified by identifier.
    def value_definition(identifier)
      @value_definitions[identifier]
    end


    # Sets the currently active value list to the one identified by identifier.
    def activate_value_list(identifier)
      @active_value_list_identifier = identifier
    end


    # Returns the "active value list", e.g. 'production' or 'staging'. NOTE: This list is the middle tier of values, and there may be overrides that have precedence over the values in this list. Use active_values() get the currently-active values of each derp var.
    def active_value_list
      @value_lists[@active_value_list_identifier]
    end


    # Register a value list with a name. A value list is just a dictionary of identifiers (symbols) mapped to values (strings).
    def define_value_list(identifier_sym, values = {})
      @value_lists[identifier_sym] = values
    end


    # Override the value associated with identifier. This is used when the user specifies a value for a derp var, and the override value has the highest precedences, so it will override the value for identifier in the currently active value list (if any) and the default value (if any).
    def override(identifier, value)
      @value_overrides[identifier] = value
    end


    # Return the active value for each derp var. The precedence is: 1. value overrides, 2. active value list, 3. derp var default value
    def active_values

      result = {}

      @value_definitions.keys.each do |identifier|
        result[identifier] = self[identifier]
      end
      result
    end

    # Returns the active value associated with a derp var.
    def [](identifier)

      value_definition =  @value_definitions[identifier]
      raise "Undefined deploy value: #{identifier}" if value_definition.nil?

      active_vlist  = active_value_list || {}
      override_vlist = @value_overrides || {}

      return override_vlist[identifier] || active_vlist[identifier] || value_definition.default
    end

  end

end
