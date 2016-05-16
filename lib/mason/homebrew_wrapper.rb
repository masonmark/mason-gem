# Wrap homebrew and perform its most useful tasks.
#-

module Mason

  class HomebrewWrapper < Mason::CommandWrapper

    def initialize(command = nil)
      if command.nil?
        @command = path_to_brew
      end
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


    def installed?
      installed_version != nil
    end


    # Build a proto-command
    def build_command
      cmd = CommandWrapper.new
      # urgh
    end


    # Do the install. If already installed, do nothing and return a success value.
    def install_homebrew
      if installed?
        cmd = CommandWrapper.new
        cmd.exit_status = 0
        cmd.expected_exit_status = 0
        cmd.stdout = "OK. Homebrew is already installed, so no installation is required."
      else
        raise NotYetImplementedError
      end

      cmd
    end

    def install
      # this is a brew command, so should be used for 'brew install package'
      raise NotYetImplementedError
    end

    def doctor
      # exit_status 1 means doctor found some shit to warn about
      cmd = CommandWrapper.new "#{path_to_brew} doctor"
      cmd.working_directory = path_to_brew
      cmd.run
      cmd
    end


    def update(print_on_failure: interactive?) # make this an instance option?
      cmd = CommandWrapper.new "#{path_to_brew} update"
      cmd.working_directory = path_to_brew
      cmd.run

      if cmd.exit_status != 0 && print_on_failure
        puts cmd.to_s :full
      end

      cmd
    end



    def run
      raise HomebrewNotInstalledError unless installed?



    end

    def path_to_brew
      # for now, only find it if 'which' can find it

      which_brew = CommandWrapper.run_command 'which brew'
      if which_brew.exit_status == 0
        path = which_brew.stdout.chomp
      end

      path if path != nil && path.length > 0
    end


    class HomebrewNotInstalledError < StandardError
    end

  end # class HomebrewWrapper

end # module Mason
