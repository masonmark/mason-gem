
require 'pathname'
require 'tempfile'
require 'yaml'

class Derployer

  attr_accessor :current_value_list_identifier
    # only one value list can be "current"

  def initialize(name = nil)

    @name = name

    @value_definitions = {}
      # The list of DerpVal instances that define what deploy values exist.
      # {symbol (DerpVal identifier): DerpVal instance}

    @value_lists = {}
      # The named lists of values (e.g., :production, :staging, etc)
      # {symbol (id of vlist): {symbol (DerpVal identifier): string}}

    @value_overrides = {}
      # User-specified overrides (e.g. entered on command line)

    @tempfile_hospital = []
      # keeps tempfile instances from deallocing when var goes out of scope


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

    Kernel.system cmd

    if block_given?
      yield
    else
      die "y u no give run block!!!"
    end
  end

  def sysadmin_username
    return self[:sysadmin_username]
  end


  private

  def infer_ssh_key_path
    path_to_root + 'ssh_keys' + "#{ self[:server_type] }.pem"
  end

end
