require 'minitest/autorun'
require 'mason'
require 'pathname'


class DerployerTests < Minitest::Test

  def setup
    @derp = Derployer.new
  end


  def test_ansible_vault_read
    my_path  = Pathname.new(File.expand_path __FILE__)
    parent   = my_path.parent
    resource = parent + 'test_derployer' + 'vault_encrypted_file'

    # password is 'foo'

    # actual   = @derp.ansible_vault_read resource
      # w/o password it would be interactive, NG for tests

    actual = @derp.ansible_vault_read resource, password: 'foo'

    expected = "foo bar baz\n"

    assert_equal expected, actual
  end


  def test_write_temp_file
    text = 'fucklock'
    path = @derp.write_temp_file text
    read = IO.read path

    assert_equal read, text
  end

end
