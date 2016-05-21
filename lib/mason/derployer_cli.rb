class Derployer

  # Get (stripped) user input.
  def ask(q, a='')
    puts q
    STDIN.gets.strip
  end


  # Exit with fatal error message.
  def die(msg="unknown problem occurred")
    abort [
    "",
    "🐒",
    " ⌇",
    " 💩  DERP!! Um, whut: #{msg}",
    "",
    "",
     ].join("\n")
  end

  def putz(obj, prefix = "📦  ")
    puts "#{ prefix }#{ obj }"
  end


  # Show introductory text.
  def greet_user

    path_to_tool = File.expand_path $PROGRAM_NAME

    putz ""
    putz "--- DErPLOYer: #{ name } ---"
    putz "(#{ path_to_tool })"
    putz ""
    putz "This tool can help provision a server and/or deploy an app."
    putz "With no args, this script will use the last-used or default settings."
    putz ""
    putz ""
  end


  # Kludge-process args
  def process_args


    # use slop you reject!! and self-bundle you trasher!

    if ARGV.include? 'reset'
      puts "Resetting all settings to default."
      settings_write({})
    end

    vlist_identifiers = @value_lists.keys
    settings_names_from_args = vlist_identifiers.select { |identifier| ARGV.include? identifier.to_s }
    name_of_settings_to_load = settings_names_from_args.last
      # kludge: since we dont parse opts for real (yet), just use last valid value:

    if ARGV.include? name_of_settings_to_load

      putz "Initializing with settings for '#{ name_of_settings_to_load }'"
      activate_value_list name_of_settings_to_load.to_sym

    else
      previous_settings = settings_read
      if previous_settings.count > 0
        putz "Initializing with last-used settings."

        #@active_settings.merge! previous_settings
        putz "FIX THAT: NOT REIMPLEMENTED"


      else
        putz "Initializing with default settings."
      end
    end
  end


  def change_setting(user_input)
    setting_number = user_input.to_i
    setting_index  = setting_number - 1
    setting_name   = active_settings.keys[setting_index] # ordered hash ftw
    valid_values   = valid_settings_values[setting_name]
    new_setting    = nil

    if setting_number < 1 || setting_number > active_settings.count
      puts "Sorry, '#{user_input}' is not a valid selection. Please try again.\n"
    elsif valid_values
      new_setting = select_value_from_list setting_name, valid_values
    else
      new_setting  = ask "Enter value#{' (' + valid_values.join('/') +')' if valid_values} for #{setting_name}: [#{active_settings9[setting_name]}]"
    end

    if validate_user_input setting_name, new_setting
      active_settings[setting_name] = new_setting
    else
      error_message = "👹  Warning: '#{new_setting}' is not an acceptable value for #{setting_name}; settings were not changed."
    end

    confirm_settings error_message
  end


  def select_value_from_list(setting_name, valid_values)
    setting_name = setting_name.to_sym
    puts "\nSelect the new value for #{setting_name}:"

    answers = []
    valid_values.each_with_index do |value, index|
      num = index + 1
      puts "[#{num}] #{value}"
      answers << "#{num}"
    end
    answers << ''

    answer = ask "\n[Enter/Return] accept current value: #{ active_settings[setting_name] }"

    if answer == ''
      active_settings[setting_name]
    elsif answers.include? answer
      index = answer.to_i - 1
      valid_values[index]
    else
      puts "Sorry, #{answer} is not a valid selection. Please try again."
      select_value_from_list setting_name, valid_values
    end
  end


  def validate_user_input(setting, value)
    valid_values = valid_settings_values[setting]
    if valid_values
      valid_values.include? value
    else
      ! [nil, ''].include?(value)
    end
  end


  def confirm_settings(error_message=nil)
    if error_message
      putz ''
      putz error_message
    end

    putz ""
    putz "READY TO DEPLOY WITH THESE SETTINGS:"
    putz ""

    i = 1
    active_settings.each do |k, v|
      putz "[#{i.to_s}] #{k}: #{v}"
      i += 1
    end
    putz ""

    answer = ask "Enter an item number to change, or Return to continue: "

    if answer != ''
      putz ""
      change_setting answer
    end
  end

end
