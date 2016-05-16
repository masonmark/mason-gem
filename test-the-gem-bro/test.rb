#! /usr/bin/env ruby

require 'mason'

brew = Mason::HomebrewWrapper.new

brew.interactive = true


install_cmd = brew.install_homebrew

unless install_cmd.ok?
  abort "installation of Homebrew failed"
end

doctor_command = brew.doctor

unless doctor_command.ok?
  abort "brew doctor failed"
end


update_command = brew.update

unless update_command.ok?
  abort "brew update failed"
end


puts "OK: EXECUTED THIS COMMAND:"
puts update_command.to_s :full

