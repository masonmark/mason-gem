#! /usr/bin/env ruby

require 'mason'

foo = Mason::Mason.new

puts "Here's a Mason instance: #{foo}"

puts "Will it boogie?"

foo.boogie

bar = Mason::CommandWrapper.new
bar.run