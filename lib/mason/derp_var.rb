class DerpVar

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


  def validate(value)
    enforce == false || allowed_values.nil? || allowed_values.include?(value)
  end

  def predefined_values_for_edit_menu
    return @allowed_values
  end

end
