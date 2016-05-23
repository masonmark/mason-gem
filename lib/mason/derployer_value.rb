class Derployer

  # Define a new deploy value. Conceptually, a deploy value is a value (currently only strings supported) with a unique name (expressed as a ruby symbol). For convenience, they define a bunch of metadata also, e.g. allowed values, info/help text, etc.
  def define(dict)
    raise "Can't define value without at least an identifier and intial value." unless dict.count > 0

    # ordered hash FTW
    identifier = dict.keys[0]

    allowed_values = dict.values[0]
    allowed_values = [allowed_values] unless allowed_values.is_a? Array

    dv = DerpVar.new identifier: identifier,
                     allowed_values: allowed_values,
                     info: dict[:info],
                     enforce: dict[:enforce] == true

    @value_definitions[dv.identifier] = dv
  end


  def value_definition(identifier)
    @value_definitions[identifier]
  end


  def activate_value_list(identifier)
    @active_value_list_identifier = identifier
  end

  # Returns the "active value list", e.g. 'production' or 'staging'. NOTE: This list is the middle tier of values and there may be overrides that have precedence over the values in this list. User active_values() get the currently-active values of each derp var.
  def active_value_list
    @value_lists[@active_value_list_identifier]
  end


  #FIXME: rename?
  def define_value_list(identifier_sym, values = {})
    @value_lists[identifier_sym] = values
  end


  def override(identifier, value)
    @value_overrides[identifier] = value
  end


  def valid_values_for(identifier)
    value_definition(identifier).allowed_values
  end


  # def valid_settings_values
  #
  #   #FIXME: make these registerable
  #
  #   {
  #       ansible_playbook:    ['ansible/site.yml', 'ansible/test-playbook.yml'],
  #       default_rails_env:   ['production', 'development'],
  #       deploy_application:  ['yes', 'no'],
  #       deploy_git_revision: ['master', 'none'],
  #       machine_type:        ['generic', 'vmware-fusion'], # because, there are several vmware-specific hacks we need to do.
  #       server_type:         ['development', 'staging', 'production'], # the intended purpose of the server (controls rails env, credentials)
  #   }
  # end


  # Return the active value for each derp var. The precedence is: 1. value overrides, 2. active value list, 3. derp var default value
  def active_values

    result = {}

    @value_definitions.keys.each do |identifier|
      result[identifier] = self[identifier]
    end
    result
  end

  def [](identifier)

    value_definition =  @value_definitions[identifier]
    raise "Undefined deploy value: #{identifier}" if value_definition.nil?

    active_vlist  = active_value_list || {}
    override_vlist = @value_overrides || {}

    return override_vlist[identifier] || active_vlist[identifier] || value_definition.default
  end



end


