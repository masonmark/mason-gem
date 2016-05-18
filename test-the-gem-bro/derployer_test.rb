#!/usr/bin/env ruby

require 'mason'

∂ = Derployer.new()

∂.register_settings :production, {

  ansible_playbook:    '/Users/mason/Code/rollerball/ansible/site.yml',
  default_rails_env:   'production',
  deploy_application:  'yes',
  deploy_git_revision: 'master',
  machine_type:        'generic',
  override_ssh_key:    '~/id_rsa',
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
    target_host:         '192.168.11.79',
}

∂.run {

  puts "THE END BRO!"

  ∂.ask 'derp?'
}


