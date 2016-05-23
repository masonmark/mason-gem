require 'mason/command_wrapper'
require 'mason/derployer'
require 'mason/derployer_cli'
require 'mason/derployer_io'
require 'mason/derployer_ansible'
require 'mason/derployer_value'
require 'mason/derp_var'

module Mason

  class Mason # we also moved the old Mason class into the new Mason module.

    def boogie
      puts "Sorry, the boogie feature has been removed in this new version."
    end

  end

end
