class Derployer

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

  def ansible_vault_password_from_environment
    ENV['DERPLOYER_ANSIBLE_VAULT_PASSWORD']
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
       "--ask-vault-pass",
       extra_vars_str,
       playbook
     ].join " \\\n" # can't have whitespace after \ in shell
  end

end
