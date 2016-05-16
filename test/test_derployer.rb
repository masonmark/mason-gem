require 'minitest/autorun'
require 'mason'


class DerployerTests < Minitest::Test

  def setup
    @derp = Derployer.new
  end

  # def test_ansible_vault_read
  #   src      = "/Users/mason/Code/rollerball/ssh_keys/production.pem"
  #   actual   = @derp.ansible_vault_read src
  #   expected = "foo bar baz"
  #
  #   assert_equal expected, actual
  # end
  
  def test_write_temp_file
    text = "fucklock"
    path = @derp.write_temp_file text
    read = IO.read path

    assert_equal read, text
  end

end
