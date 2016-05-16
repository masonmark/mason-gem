#!/usr/bin/env ruby

require 'mason'


PATH_TO_ME      = Pathname.new(File.expand_path(__FILE__))
PATH_TO_ROOT    = PATH_TO_ME.parent.parent
INVOCATION_NAME = PATH_TO_ME.basename
PATH_TO_BUNDLE  = PATH_TO_ROOT + "vendor" + "bundle"


∂ = Derployer.new()

∂.register_settings :production, {

  ansible_playbook:    'ansible/site.yml',
  default_rails_env:   'production',
  deploy_application:  'yes',
  deploy_git_revision: 'master',
  machine_type:        'generic',
  override_ssh_key:    '~/id_rwsa',
  server_type:         'production',
  sysadmin_user_name:  'centos',
  target_host:         '52.69.141.51',
  target_ssh_port:      22,
}

∂.register_settings :development, {

	  default_rails_env:   'development',
    deploy_git_revision: 'none',
    machine_type:        'vmware-fusion',
    server_type:         'development',
    sysadmin_user_name:  'centos',
    target_host:         '192.168.11.79'
}

∂.run {

  puts ∂.path_to_root

	path_to_private_key = ∂.write_ssh_key_to_temp_file

	server_type     = ∂[:server_type]
  target_host     = ∂[:target_host]
	target_ssh_port = ∂[:target_ssh_port]

	inventory_content = [
		"[#{ server_type }]",
		"ansible_ssh_host=#{ target_host }",
		"ansible_ssh_host=#{ target_ssh_port }",
	].join("\n")

  puts 'inventory_content:'
  puts inventory_content

  inventory_file = Tempfile.new 'inventory'
  inventory_file.write inventory_content
  inventory_file.close

  # instead of string formatting, make ∂ do it from objects

  extra_vars = [:sysadmin_username, :server_type, :deploy_git_revision, :default_rails_env, :machine_type]
  playbook   = ∂[:playbook]

  cmd = ∂.build_ansible_command inventory:  inventory_file.path,
                                playbook:   playbook,
                                extra_vars: extra_vars,
                                ssh_key:    path_to_private_key

  puts cmd

}


