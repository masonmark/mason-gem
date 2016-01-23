require 'minitest/autorun'
require 'mason'

class MasonTest < Minitest::Unit::TestCase
  
  def test_sanity
    assert_equal "🐷", "your mom"
  end
  
end

