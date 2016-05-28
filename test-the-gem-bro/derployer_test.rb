#!/usr/bin/env ruby

unless ENV['BUNDLE_GEMFILE']
  puts "  ☠   "
  puts "  ☠   ERROR: BUNDLER ENVIRONMENT REQUIRED."
  puts "  ☠   "
  puts "  ☠   It seems you are not using Bundler to"
  puts "  ☠   invoke this script. It is required."
  puts "  ☠   "
  puts "  ☠   Please re-run this script something like:"

  puts ""
  puts "       bundle exec #{$PROGRAM_NAME} #{ARGV}"

  puts "  ☠   "
  abort()
end



require 'mason'

∂ = Derployer.new()

# Define some deploy settings.

∂.define foo: 'bar'

∂.define ansible_playbook: ['/Users/mason/Code/rollerball/ansible/site.yml'],
                     info: "path to Ansible playbook that will be run"


∂.define machine_type: ['generic', 'vmware-fusion'],
                 info: "vmware-fusion enabled hacks required by HGFS (e.g., disabling SELinux) are performed",
              enforce: true

∂.define deploy_application: ['production', 'development'] #FUCK THIS ONE

∂.define deploy_application:  'yes'
∂.define deploy_git_revision: 'master'
∂.define override_ssh_key:    '~/id_rsa'
∂.define server_type:         'production'
∂.define sysadmin_username:  'centos'
∂.define target_host:         '52.69.141.51'
∂.define target_ssh_port:      22


∂.define_value_list :production, {} # that just means all settings are default

∂.define_value_list :development, {

	  default_rails_env:   'development',
    deploy_git_revision: 'none',
    machine_type:        'vmware-fusion',
    server_type:         'development',
    sysadmin_username:   'centos',
    target_host:         '192.168.11.79',
}


∂.run()

# ∂.run {
#
#   puts "THE END BRO!"
#
# }


