#! /usr/bin/env ruby

require 'mason'

foo = Mason::Mason.new

puts "Here's a Mason instance: #{foo}"

puts "Will it boogie?"

foo.boogie

bar = Mason::CommandWrapper.new
bar.command = 'ls -laR /usr/local/bin'
bar.run

puts "bar: #{bar}"
puts "bar.stdout: #{bar.stdout}"