class Derployer

  # Define a new deploy value. Conceptually, a deploy value is a value (currently only strings supported) with a unique name (expressed as a ruby symbol). For convenience, they define a bunch of metadata also, e.g. allowed values, info/help text, etc.
  def define(dict)
    raise "Can't define value without at least an identifier and intial value." unless dict.count > 0

    # ordered hash FTW
    ident = dict.keys[0]
    value = dict.values[0]
    allow = dict[:allow] || []
    allow << value unless allow.include? value

    dv = DerpVal.new identifier: ident,
                 allowed_values: allow,
                           info: dict[:info],
                        enforce: dict[:enforce] == true

    @value_definitions[dv.identifier] = dv
  end

  #FIXME: rename?
  def define_value_list(identifier_sym, values = {})
    @registered_settings[identifier_sym] = values
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
