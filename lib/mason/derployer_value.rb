class Derployer

  # Define a new deploy value. Conceptually, a deploy value is a value (currently only strings supported) with a unique name (expressed as a ruby symbol). For convenience, they define a bunch of metadata also, e.g. allowed values, info/help text, etc.
  def define(dict)
    raise "Can't define value without at least an identifier and intial value." unless dict.count > 0

    # ordered hash FTW
    identifier = dict.keys[0]

    allowed_values = dict.values[0]
    allowed_values = [allowed_values] unless allowed_values.is_a? Array

    dv = DerpVal.new identifier: identifier,
                 allowed_values: allowed_values,
                           info: dict[:info],
                        enforce: dict[:enforce] == true

    @value_definitions[dv.identifier] = dv
  end

  #FIXME: rename?
  def define_value_list(identifier_sym, values = {})
    @value_lists[identifier_sym] = values
  end


  def override(identifier, value)
    @value_overrides[identifier] = value
  end

  def valid_settings_values

    #FIXME: make these registerable

    {
        ansible_playbook:    ['ansible/site.yml', 'ansible/test-playbook.yml'],
        default_rails_env:   ['production', 'development'],
        deploy_application:  ['yes', 'no'],
        deploy_git_revision: ['master', 'none'],
        machine_type:        ['generic', 'vmware-fusion'], # because, there are several vmware-specific hacks we need to do.
        server_type:         ['development', 'staging', 'production'], # the intended purpose of the server (controls rails env, credentials)
    }
  end


  def active_values
    result = {}

    current_vlist  = @value_lists[current_value_list_identifier] || {}
    override_vlist = @value_overrides

    @value_definitions.each do |identifier, derpval|
      result[identifier] = override_vlist[identifier] || current_vlist[identifier] || derpval.default
    end
    result
  end

  def [](ident)
    value =  @value_definitions[ident]

    raise "Undefined deploy value: #{ident}" if value.nil?
    list = @value_lists[current_value_list_identifier]
    override_value = list && list[ident]

    return override_value || value.default
  end



end


class DerpVal

  attr_reader :identifier, :allowed_values, :enforce

  def initialize(identifier:, allowed_values:, info: nil, enforce: false)
    @identifier     = identifier
    @allowed_values = allowed_values
    @info           = info
    @enforce        = enforce

  end

  def default
    allowed_values[0]
  end

end
