# Wrap homebrew and perform its most useful tasks.
#-

module Mason

  class HomebrewWrapper < Mason::CommandWrapper

    def initialize(command = nil)
      if command.nil?
        @command = path_to_brew
      end
    end


    def run
      raise HomebrewNotInstalledError if installed_version.nil?



    end

    def path_to_brew
      # for now, only find it if 'which' can find it

      which_brew = CommandWrapper.run_command 'which brew'
      if which_brew.exit_status == 0
        path = which_brew.stdout.chomp
      end

      path if path != nil && path.length > 0
    end

    def installed_version
      if path_to_brew
        version = CommandWrapper.run_command "#{path_to_brew} --version"
        if version.exit_status == 0 && version.stdout.length > 0
          return version.stdout.chomp
        end
      end
      return nil # not installed or couldn't make it work
    end

    class HomebrewNotInstalledError < StandardError
    end

  end # class HomebrewWrapper

end # module Mason
