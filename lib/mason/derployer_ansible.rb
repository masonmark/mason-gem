class Derployer

  # Decrypt file with ansible vault and return contents (prompts user for password if necessary).
  def ansible_vault_read(path_to_encrypted_file, name: 'encrypted resource')

    puts "(**** BRUH!!!! #{callee}"
    exit_status = 666
    while exit_status != 0
      # because ansible value may prompt

      password = ansible_vault_password_from_environment
      if password
        puts "**** FOUND PASSWORD BRO: #{password}"
        active_settings[:ansible_vault_password] = password
      end

      decrypted_contents = %x( ansible-vault view #{ path_to_encrypted_file } )
      exit_status = $?.exitstatus

      if exit_status != 0
        puts "⚠️ ️Unable to decrypt #{ name } at #{path_to_encrypted_file}. Please try again.\n\n"
      end
    end

    decrypted_contents
  end


  def ansible_vault_password_from_environment
    env['DERPLOYER_ANSIBLE_VAULT_PASSWORD']
  end

  def write_ansible_inventory_file

    server_type     = self[:server_type]
    target_host     = self[:target_host]
    target_ssh_port = self[:target_ssh_port]

    inventory_content = [
      "[#{ server_type }]",
      "ansible_ssh_host=#{ target_host }",
      "ansible_ssh_port=#{ target_ssh_port }",
    ].join("\n")

    write_temp_file(inventory_content)
  end


end
