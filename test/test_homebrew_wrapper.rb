require 'minitest/autorun'

require 'mason/command_wrapper'
require 'mason/homebrew_wrapper'

class HomebrewWrapperTest < MiniTest::Unit::TestCase

  def setup
    # Do nothing
  end

  # Fake test

  def test_version
    version = Mason::HomebrewWrapper.new.installed_version
    assert version.start_with? 'Homebrew'
  end


  def test_fuckery

    cw = Mason::CommandWrapper

    w = cw.run_command "which brew"


  end
end