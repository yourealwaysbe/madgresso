Gem::Specification.new do |s|
  s.name        = 'madgresso'
  s.version     = '0.0.1'
  s.date        = '2016-10-14'
  s.summary     = 'Interact with Agresso expense claims from files/command line with a Capybara based script'
  s.description = 'Interact with Agresso expense claims from files/command line with a Capybara based script, at least for the installation i have to deal with...'
  s.authors     = ['Matthew Hague']
  s.email       = 'matthewhague@zoho.com'
  s.files       = ['lib/madgresso.rb',
                   'lib/configuration.rb',
                   'lib/expenses.rb',
                   'lib/interactive.rb',
                   'bin/madgresso']
  s.add_runtime_dependency 'selenium-webdriver', ['~>2.53']
  s.add_runtime_dependency 'capybara', ['~>2.10']
  s.homepage    = 'https://github.com/yourealwaysbe/madgresso'
  s.license     = 'MIT'
  s.executables << 'madgresso'
end
