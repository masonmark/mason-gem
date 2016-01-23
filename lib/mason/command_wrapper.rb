module Mason
  
  require 'open3'
  

  class CommandWrapper
    
    attr_accessor :command, # the whole command string with args, e.g. 'ls -al /foo'
                  :working_directory, 
                  :expected_exit_status,
                  :raise_on_bad_exit,
                  :exit_status,
                  :stdout,
                  :stderr,
                  :start_time,
                  :end_time
    
    def initialize(command = nil)
      @command              = command
      @working_directory    = Dir.pwd
      @expected_exit_status = 0
      @raise_on_bad_exit    = true
      @start_time           = nil
      @end_time             = nil
      @stdout               = nil
      @stderr               = nil
      @exit_status          = nil

    end
    
    def run()
      @exit_status, @stdout, @stderr, @start_time, @end_time = run_command(@command)
      
      if @raise_on_bad_exit && (@exit_status != @expected_exit_status)
        raise UnexpectedExitStatusError.new("#{to_s :short}: expected #{@expected_exit_status} but got #{@exit_status}")
      end
    end
    
    
    def run_command(cmd_str)
      # run cmd in the shell, wait for exit, and return exit_status, stdout_output, stderr_output, start_time, end_time
      # e.g. exit_status, stdout_output, stderr_output = run_command 'ls -l /'

      if [nil, ''].include? cmd_str
        raise InvalidCommandError.new("invalid command: #{cmd_str}")
      end

      start_time = Time.now

      # Mason 2010-10-17: here is one way to run a one shot command line tool
      # subprocess in Ruby 1.9. The read calls block until the subprocess exits,
      # so when you want get fancy and communicate with the subprocess then
      # this isn't what you need. Also, there's no mechanism yet to have a timeout or
      # interrupt a task that is e.g. stuck waiting for input or otherwise infinite.

      stdin, stdout, stderr, wait_thr = Open3.popen3(cmd_str)
      # pid = wait_thr[:pid]  # pid of the started process.
      # puts "Execute command: " + cmd
      # puts "pid: " + pid.to_s

      stdout_output = stdout.read
      stderr_output = stderr.read
        # those block until exit, so after this line subprocess is done

      status = wait_thr.value  # Process::Status object returned.

      stdin.close  # per docs, stdin, stdout and stderr should be closed in this form.
      stdout.close # dunno if that is really necessary in this use case but it does
      stderr.close # not seem to hurt...

      exit_status = status.exitstatus
      end_time    = Time.now
      
      return exit_status, stdout_output, stderr_output, start_time, end_time
    end

    def self.run_command(cmd_str)
      cw = self.new cmd_str
      cw.run
    end
    
    
    def to_s(style = :short)
      "#{self.class.name}: #{@command}"
    end
    
    # def run
    #   nope = "nope nope!"
    #   puts nope
    #   return nope
    # end
    
    class InvalidCommandError < StandardError
    end
    
    class UnexpectedExitStatusError < StandardError
    end
    
  end # CommandWrapper class
  
end # Mason module
