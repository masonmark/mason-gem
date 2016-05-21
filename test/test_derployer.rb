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

  def test_active_values
    d = @derp
    d.define foo: ['bar', 'baz']
    d.define ass: 'hat'

    expected = {foo: 'bar', ass: 'hat'}
    assert_equal expected, d.active_values

    d.define_value_list :snausages, {
        foo: 'SNAUSAGES!!'
    }
    d.activate_value_list :snausages

    expected  = {foo: 'SNAUSAGES!!', ass: 'hat'}
    assert_equal expected, d.active_values

    d.override :foo, 'taco salad'
    expected = {foo: 'taco salad', ass: 'hat'}
    assert_equal expected, d.active_values


  end

  def test_value_creation
    d = @derp
    d.define foo: ['bar', 'baz']
    d.define ass: 'hat'

    d.define_value_list :production, {}

    d.define_value_list :snausages, {
      foo: 'baz'
    }

    d.activate_value_list nil # should mean all vals are default
    assert_equal 'bar', d[:foo]
    assert d[:ass] == 'hat'

    d.activate_value_list :production
    assert d[:foo] == 'bar'
    assert d[:ass] == 'hat'

    d.activate_value_list :snausages
    assert d[:foo] == 'baz'
    assert d[:ass] == 'hat'

  end

end
