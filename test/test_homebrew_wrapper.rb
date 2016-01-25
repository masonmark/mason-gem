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
    # mason 2016-01-25: aotw look like: "0.9.5 (git revision 30261; last commit 2015-08-12)"
    # no longer valid: assert version.start_with? 'Homebrew'
    assert version.include? 'git revision'
  end


  def test_fuckery

    cw = Mason::CommandWrapper

    w = cw.run_command "which brew"


  end
end