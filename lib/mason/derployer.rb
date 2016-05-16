
require 'pathname'
require 'tempfile'
require 'yaml'

class Derployer

  def initialize(name = nil)
    @name = name
    @registered_settings  = {} # keys are identifiers, values are settings dictionaries
    @active_settings_name = nil # identifier of a registered settings dict
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


  def default_settings
    if first = @registered_settings.first
      first[1]
    else
      {}
    end
  end


  def active_settings
    @registered_settings[@active_settings_name] || default_settings
  end


  def [](ident)
    return active_settings[ident]
  end


  def run

    puts "Running bro"

    if block_given?
      yield
    end
  end

  def sysadmin_username
    return active_settings[:sysadmin_username]
  end


  def build_ansible_command(inventory:, playbook:, extra_vars:, ssh_key:)

    puts __FILE__
    puts $PROGRAM_NAME
    puts File.expand_path $PROGRAM_NAME
    [
      "ansible-playbook ", # Mason 2016-03-15: you can add -vvvvv here to debug ansible troubles.
       "--inventory-file=#{inventory}",
       "--user='#{sysadmin_username}'",
       "--private-key='#{ssh_key}'"
     ].join ' '
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

    t = Tempfile.new 'private_key.pem'
    t.write src_file_contents
    t.close

    @tempfile_hospital << t
      # Mason 2016-03-15: You MUST keep a ref to a Tempfile-created temp file around; if not, the file will be deleted when instance is GC'd. Caused shitty 30 min headache bug, where SSH connection failed because the key disappeared during connecting!

    FileUtils.chmod 0600, t.path # Mason 2016-03-15: may not be necessary (?), but doesn't hurt.

    puts "Wrote SSH key to #{t.path}"
    t.path
  end


  private

  def infer_ssh_key_path
    path_to_root + 'ssh_keys' + "#{ self[:server_type] }.pem"
  end

end
