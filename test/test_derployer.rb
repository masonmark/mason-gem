require 'minitest/autorun'
require 'mason'
require 'pathname'


class DerployerTests < Minitest::Test

  def append_output(new_output)
    @output ||= ''
    @output += new_output
  end

  def setup
    @output = nil
    pblock = lambda {|what| self.append_output(what)}
    @derp = Derployer.new('TEST', print_block: pblock)
  end


  def test_test_can_capture_output
    @derp.print "yep"
    assert_equal "yep\n", @output
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


  def test_change_setting
    
    d = @derp
    d.define foo: ['bar']

    d.change_setting :foo, user_inputs: ['baz']
    assert_equal 'baz', d[:foo]

    # Now we have changed the value, so on next edit the menu should appear. Pressing Return should mean this returns nil (the effect of which is to keep the current value):
    actual = d.change_setting :foo, user_inputs: ['']
    assert_equal 'baz', d[:foo]

    # choose things from menu:
    d.define whut: ['whut', 'in', 'the']
    d.change_setting :whut, user_inputs: [3]
    assert_equal 'the', d[:whut]

    d.change_setting :whut, user_inputs: [2]
    assert_equal 'in', d[:whut]

    d.change_setting :whut, user_inputs: ['']
    assert_equal 'in', d[:whut]

    # use 'i' to input directly, but then just hit Return to accept current value:
    d.change_setting :whut, user_inputs: ['i', '']
    assert_equal 'in', d[:whut]

    # do again but this time enter something
    d.change_setting :whut, user_inputs: ['i', 'snausages', '']
    assert_equal 'snausages', d[:whut]

  end


  def test_edit_value
    # When this test case was first written, edit_value changed state. Now it doesn't so this test is less meaningful (but not totally worthless, so it's still here.)
    d = @derp
    d.define foo: ['bar']
    actual = d.edit_value :foo, user_inputs: ['baz']
    assert_equal 'baz', actual

    actual = d.edit_value :foo, user_inputs: ['']
    assert_nil actual

    # choose things from menu:
    d.define whut: ['whut', 'in', 'the']
    actual = d.edit_value :whut, user_inputs: [3]
    assert_equal 'the', actual

    actual = d.edit_value :whut, user_inputs: [2]
    assert_equal 'in', actual

    # use 'i' to input directly, but then just hit Return to accept current value:
    actual = d.edit_value :whut, user_inputs: ['i', '']
    assert_equal nil, actual

    # do again but this time enter something
    actual = d.edit_value :whut, user_inputs: ['i', 'snausages', '']
    assert_equal 'snausages', actual
  end


  def test_output_of_edit_value_non_editable_case
    d = @derp
    d.define foo: ['bar'], enforce: true

    expected = <<~ERROR_OUTPUT

     ===== EDIT VALUE: foo =====================================================================

     Derrrp! can't edit foo: it is configured with only 1 valid value (bar)
    ERROR_OUTPUT

    d.edit_value :foo

    assert_equal expected, @output
  end


  def test_output_of_edit_value_enforced_choice_case
    d = @derp
    d.define machine_type: ['generic', 'vmware-fusion'],
                     info: "vmware-fusion enabled hacks required by HGFS (e.g., disabling SELinux) are performed",
                  enforce: true

    d.edit_value :machine_type, user_inputs: ['2']

    expected = <<~OUTPUT

      ===== EDIT VALUE: machine_type ============================================================

      [1] generic
      [2] vmware-fusion

      Choose from menu, or press ↩︎ to accept current value: generic
      > 2

    OUTPUT

    assert_equal expected, @output
  end


  def test_print_replacement
    # make sure it actually works

    pblock = lambda {|what| return "HUMPTY#{what}"}
    humpty_derpty = Derployer.new('HUMPTY', print_block: pblock)

    output  = ""
    output += humpty_derpty.print "foo"
    output += humpty_derpty.print "bar"

    expected = "HUMPTYfoo\nHUMPTYbar\n"
    assert_equal expected, output
  end


  def test_read_settings
    old = Derployer.new('test_read_settings-bro')
    new = Derployer.new('test_read_settings-bro')

    old.define foo: 'bar'
    old.define bar: 'baz'
    old.define baz: 'whut'

    old.settings_write

    expected = {foo: 'bar', bar: 'baz', baz: 'whut'}
    actual   = old.settings_read
    assert_equal expected, actual


    old.override :foo, 'override1'
    old.override :bar, 'override2'
    old.override :baz, 'override3'

    old.settings_write

    expected = {foo: 'override1', bar: 'override2', baz: 'override3'}
    actual   = old.settings_read
    assert_equal expected, actual

    # Finally, test that a newer derployer reading settings that no longer apply filters them out:

    new.define bar: 'baz'
    new.define baz: 'whut'
    new.define ass: 'hat'

    expected = {bar: 'override2', baz: 'override3'} # no more foo
    actual   = new.settings_read
    assert_equal expected, actual
  end

  def test_read_write_named_settings
    d = @derp

    d.define foo: ['bar', 'baz']
    d.define ass: 'hat'

    d.settings_write name: 'production'

    d.override :foo, 'snausages'

    d.settings_write name: 'dev-vm-at-my-house'

    expected = {foo: 'bar', ass: 'hat'}
    actual   = d.settings_read name: 'production'
    assert_equal expected, actual

    expected = {foo: 'snausages', ass: 'hat'}
    actual   = d.settings_read name: 'dev-vm-at-my-house'
    assert_equal expected, actual

  end

end
