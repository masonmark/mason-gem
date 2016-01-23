require 'minitest/autorun'
require 'mason/command_wrapper'

class CommandWrapperTests < MiniTest::Unit::TestCase
  # mason 2016-01-23: bringing the first bit of my standard ruby code under one roof...
  # mason 2011-08-05 fucking around porting ancient python stuff

  def setup
    @class    = Mason::CommandWrapper
    @instance = Mason::CommandWrapper.new
  end


  def test_instantiation_without_command
    # A wrapper should have no command by default, and trying to run it should raise.
    
    assert_nil @instance.command
    assert_raises(Mason::CommandWrapper::InvalidCommandError) {@instance.run}
  end
  
  
  def test_stdout
    @instance = @class.new 'echo "おはようございます"'
    @instance.run
    
    assert @instance.stdout.include? "おはよう"
    assert_equal 0, @instance.exit_status    
  end
  
  
  def test_stderr
    @instance = @class.new 'ls /bonkGRONKdonkDONK~~NONEXISTENT'
    @instance.raise_on_bad_exit = false
    @instance.run
    
    assert @instance.stderr.include? "ls:" # because any message might be localized
    refute_equal 0, @instance.exit_status    
  end


  def test_simple_ls_use_case
    @instance.command = "ls -la /"
    @instance.run

    assert_equal 0, @instance.exit_status
    assert @instance.stdout.include? "drwx" 
      # surely this will be there on any system we might use?
    assert @instance.stderr == ""
    assert @instance.exit_status == 0
  end


  def test_working_dir_is_picked_up_at_instantiate_time
    assert_equal @instance.working_directory, Dir.pwd
    
    Dir.chdir("/Users")
    @instance = Mason::CommandWrapper.new
    assert_equal @instance.working_directory, "/Users"
  end


  def test_exit_status
    @instance.raise_on_bad_exit = false
    assert_nil @instance.exit_status
    @instance.working_directory = "/Users"
    @instance.command = "ls"
    @instance.run
    assert_equal 0, @instance.exit_status

    @instance.command = "ls DOESNTEXISTfjdhsfldjkhlhdfsjk"
    @instance.run
    assert @instance.exit_status != 0
  end


  def test_run_command_return_val
    exit_status, stdout_output, stderr_output = @instance.run_command 'ls -l /'
    assert exit_status == 0
    assert stdout_output.length > 0
    assert stderr_output.length == 0
  end


  def test_should_raise_on_nonzero_exit_status
    @instance = @class.new 'ls -la'
    @instance.run
    assert_equal 0, @instance.exit_status
    
    @instance = @class.new('ls -la /dshjkflashdfklahfhsadjkfhlasdhfhasdlhfu')
    assert_raises(Mason::CommandWrapper::UnexpectedExitStatusError) {@instance.run}
    
    @instance.raise_on_bad_exit = false
    @instance.run
    assert @instance.exit_status != 0
  end
  
end
