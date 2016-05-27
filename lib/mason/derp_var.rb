class DerpVar

  attr_reader :identifier, :predefined_values, :enforce, :allow_empty_string

  def initialize(identifier:, predefined_values:, info: nil, enforce: false, allow_empty_string: false)
    @identifier         = identifier
    @predefined_values  = predefined_values
    @info               = info
    @enforce            = enforce
    @allow_empty_string = allow_empty_string
  end

  def default
    predefined_values[0]
  end


  def validate(value)
    enforce == false || predefined_values.nil? || predefined_values.include?(value)
  end

end
