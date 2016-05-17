Gem::Specification.new do |s|
  s.name        = 'mason'
  s.version     = '0.0.3'
  s.date        = '2016-05-16'
  s.summary     = "Mason!"
  s.description = "A personal utility gem by and for Mason."
  s.authors     = ["Mason Mark"]
  s.email       = 'mason@masonmark.com'
  s.files       = [
                    "lib/mason.rb",
                    "lib/mason/command_wrapper.rb",
                    "lib/mason/derployer.rb",
                    "lib/mason/derployer_cli.rb",
                    "lib/mason/derployer_io.rb",
                    "lib/mason/derployer_ansible.rb",
                  ]
  s.homepage    = 'http://masonmark.com'
  s.license     = 'MIT'
end
