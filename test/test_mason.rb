require 'minitest/autorun'
require 'mason'

class MasonTest < Minitest::Unit::TestCase
  
  def test_sanity
    refute_equal "🐷", "your mom"
  end
  
end

