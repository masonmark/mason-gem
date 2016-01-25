#! /usr/bin/env ruby

require 'mason'

brew = Mason::HomebrewWrapper.new

unless brew.installed?
  brew.install

  # FIXME: check result and so forth...
end

doctor_command = brew.doctor
if doctor_command.failed?
  puts "WOPS BRO! DOCTOR CMD FAILED BRUH!"
  puts doctor_command.to_s :full
end

# FIXME: if brew doctor found issues, then we need to ask the user what to do. If non-interactive, we need to bail unless some flag indicates otherwise.

update_command = brew.update
if update_command.failed?
  puts "WOPS BRO! CMD FAILED !"
  puts update_command.to_s :full
  abort "cant proceed bro"
end

puts "OK: EXECUTED THIS COMMAND:"
puts update_command.to_s :full

