require 'minitest/autorun'
require 'mason'


class FakeInputTests < Minitest::Test

  def setup
    @fi = Mason::FakeInput.new ['a', 'x', 'fubro', '', '3', 8, :asshat, :Q]
  end


  def test_simple
    assert_equal 'a', @fi.next
    assert_equal 'x', @fi.next
    assert_equal 'fubro', @fi.next
    assert_equal '', @fi.next
    assert_equal '3', @fi.next
    assert_equal '8', @fi.next
    assert_equal 'asshat', @fi.next
    assert_equal 'Q', @fi.next

    assert_nil @fi.next
    assert_nil @fi.next
  end

end