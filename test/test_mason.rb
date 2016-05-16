require 'minitest/autorun'
require 'mason'

class MasonTest < Minitest::Test

  def test_sanity
    refute_equal "🐷", "your mom"
  end

end

