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

end
