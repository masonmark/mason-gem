class Derployer


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

  def putz(obj, prefix = "📦  ")
    puts "#{ prefix }#{ obj }"
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
      # kludge: since we dont parse opts for real (yet), just use last valid value:

    if ARGV.include? name_of_settings_to_load

      print "Initializing with settings for '#{ name_of_settings_to_load }'"
      activate_value_list name_of_settings_to_load.to_sym

    else
      previous_settings = settings_read
      if previous_settings.count > 0
        print "Initializing with last-used settings."

        #@active_settings.merge! previous_settings
        print "FIXME: NOT REIMPLEMENTED YET BRO"


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




end
