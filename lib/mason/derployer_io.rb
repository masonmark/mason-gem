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


  # Decrypt file with ansible vault and return contents (prompts user for password if necessary).
  def ansible_vault_read(path_to_encrypted_file, name: 'encrypted resource')

    exit_status = 666
    while exit_status != 0
      # because ansible value will prompt

      # FIXME: Make it work with env var if available to avoid prompt

      decrypted_contents = %x( ansible-vault view #{ path_to_encrypted_file } )
      exit_status = $?.exitstatus

      if exit_status != 0
        puts "⚠️ ️Unable to decrypt #{ name } at #{path_to_encrypted_file}. Please try again.\n\n"
      end
    end

    decrypted_contents
  end

end
