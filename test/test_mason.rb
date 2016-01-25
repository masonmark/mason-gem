puts $LOAD_PATH

require 'minitest/autorun'
require 'mason'


module Mason


  class MasonTest < Minitest::Unit::TestCase

    def test_sanity
      refute_equal "🐷", "your mom"
    end

    def test_empty_hack
      assert empty?(nil)
    end
  end

end