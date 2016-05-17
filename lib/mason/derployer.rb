
require 'pathname'
require 'tempfile'
require 'yaml'

class Derployer

  def initialize(name = nil)
    @name                 = name
    @active_settings      = nil
    @registered_settings  = {} # keys are identifiers, values are settings dictionaries
    @run_block            = -> { puts "Derp! Somehow, this Derployer was run w/o a run_block." }

    @tempfile_hospital    = []
  end

  # Returns the name of the Deployer instance, e.g. "deploy-rollerball". Returns "generic" if no name is set.
  def name
    @name || 'generic'
  end

  # Returns a Pathname
  def path_to_root
    path_to_script = Pathname.new(File.expand_path $PROGRAM_NAME)
    path_to_parent = path_to_script.parent

    if path_to_parent.basename.to_s == 'bin'
      path_to_parent = path_to_parent.parent
    end
    path_to_parent
  end

  def register_settings(identifier, dictionary)
    @registered_settings[identifier.to_sym] = dictionary
  end


  def registered_settings_names
    @registered_settings.keys.map { |x| x.to_s }
  end

  def registered_settings(identifier)
    @registered_settings[identifier.to_sym]
  end


  def default_settings
    if first = @registered_settings.first
      first[1]
    else
      {}
    end
  end

  def fag
  end

  def valid_settings_values

    #FIXME: make these registerable

    {
      ansible_playbook:    ['ansible/site.yml', 'ansible/test-playbook.yml'],
      default_rails_env:   ['production', 'development'],
      deploy_application:  ['yes', 'no'],
      deploy_git_revision: ['master', 'none'],
      machine_type:        ['generic', 'vmware-fusion'], # because, there are several vmware-specific hacks we need to do.
      server_type:         ['development', 'staging', 'production'], # the intended purpose of the server (controls rails env, credentials)
    }
  end


  def active_settings
    @active_settings || default_settings
  end


  def [](ident)
    return active_settings[ident]
  end


  def run

    greet_user
    process_args
    confirm_settings

    path_to_private_key    = write_ssh_key_to_temp_file
    path_to_inventory_file = write_ansible_inventory_file

    # instead of string formatting, make ∂ do it from objects

    playbook   = self[:ansible_playbook]

    extra_vars = [:sysadmin_username, :server_type, :deploy_git_revision, :default_rails_env, :machine_type]

    cmd = build_ansible_command inventory: path_to_inventory_file,
                           playbook: playbook,
                         extra_vars: extra_vars,
                            ssh_key: path_to_private_key

    settings_write

    putz "\nATTEMPTING TO DEPLOY VIA ANSIBLE AS FOLLOWS:\n"

    puts cmd


    ask 'fag?'

    Kernel.system cmd

    if block_given?
      yield
    else
      die "y u no give run block!!!"
    end
  end

  def sysadmin_username
    return active_settings[:sysadmin_username]
  end


  def build_ansible_command(inventory:, playbook:, extra_vars:, ssh_key:)

     extra_vars_str = '--extra-vars "'
     extra_vars.each { |k|
     extra_vars_str += "#{ k }='#{ self[k] }' " # note trailing space
     }
     extra_vars_str += '"'

     username = self[:sysadmin_user_name]
     playbook = self[:ansible_playbook]

    [
      "ansible-playbook ", # Mason 2016-03-15: you can add -vvvvv here to debug ansible troubles.
       "--inventory-file=#{ inventory }",
       "--user='#{ username }'",
       "--private-key='#{ ssh_key }'",
       extra_vars_str,
       playbook
     ].join " \\\n" # can't have whitespace after \ in shell


  end


  private

  def infer_ssh_key_path
    path_to_root + 'ssh_keys' + "#{ self[:server_type] }.pem"
  end

end
