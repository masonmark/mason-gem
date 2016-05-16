class Derployer

  # Returns the settings path, which is partially based on the name, so if each deploy tool using this library uses a unique name, they don't clobber each other.
  def settings_path
    File.expand_path('~/.derployer-#{ name }.settings')
  end


  # Read the stored settings.
  #   FIXME: make this able to save named sets of settings
  #   FIXME: and maybe nuke or at leat filter our old obsolete settings.
  def settings_read
    result = {}
    begin
      file_contents = IO.read settings_path
      old_settings  = YAML.load file_contents
      if old_settings.class == Hash
        result = old_settings
      end
    rescue
      result = {}
    end
    result
  end


  # Save settings.
  def settings_write(settings_hash = active_settings)
    File.open settings_path, 'w' do |f|
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
    
    write_temp_file src_file_contents
  end
  
  
  # Write a string to a secure tempfile and return the path to the file.
  def write_temp_file(contents)
    t = Tempfile.new 'private_key.pem'
    t.write contents
    t.close

    @tempfile_hospital << t
      # Mason 2016-03-15: You MUST keep a ref to a Tempfile-created temp file around; if not, the file will be deleted when instance is GC'd. Caused shitty 30 min headache bug, where SSH connection failed because the key disappeared during connecting!

    FileUtils.chmod 0600, t.path # Mason 2016-03-15: may not be necessary (?), but doesn't hurt.

    t.path
  end

end
