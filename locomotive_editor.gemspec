Gem::Specification.new do |s|
  s.name        = "locomotive_editor"
  s.version     = "1.0.0.rc13"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Didier Lafforgue"]
  s.email       = ["didier@nocoffee.fr"]
  s.homepage    = "http://www.locomotivecms.com"
  s.summary     = "Locomotive Site Editor"
  s.description = "This tool allows you to quickly develop sites for your locomotive engine but locally."

  s.executables = ["locomotive_editor"]

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "locomotive_editor"

  s.add_dependency 'rack',                            '1.4.1'
  s.add_dependency 'thin',                            '~> 1.4.1'
  s.add_dependency 'sinatra',                         '~> 1.3.2'
  s.add_dependency 'haml',                            '3.1.6'
  s.add_dependency 'coffee-script',                   '~> 2.2.0'
  s.add_dependency 'therubyracer',                    '~> 0.9.10' unless (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
  s.add_dependency 'compass',                         '~> 0.12.1'
  s.add_dependency 'locomotive_liquid',               '~> 2.2.2'
  s.add_dependency 'activesupport',                   '~> 3.2.6'
  s.add_dependency 'i18n',                            '~> 0.6.0'
  s.add_dependency 'RedCloth',                        '~> 4.2.3'
  s.add_dependency 'will_paginate',                   '~> 2.3.15'
  s.add_dependency 'multi_json',                      '~> 1.3.6'
  s.add_dependency 'httmultiparty',                   '0.3.8'
  s.add_dependency 'json',                            '~> 1.7.4'
  s.add_dependency 'sinatra-i18n',                    '~> 0.1.0'
  s.add_dependency 'sinatra-flash',                   '>= 0.3.0'
  s.add_dependency 'zip',                             '~> 2.0.2'
  s.add_dependency 'faker',                           '~> 0.9.5'
  s.add_dependency 'rack-cache',                      '~> 1.1'
  s.add_dependency 'dragonfly',                       '~> 0.9.8'
  s.add_dependency 'colorize',                        '~> 0.5.8'
  s.add_dependency 'pistol'

  s.add_development_dependency 'rake',                '0.9.2'
  s.add_development_dependency 'rspec',               '~> 2.6.0'
  s.add_development_dependency 'mocha',               '0.9.12'
  s.add_development_dependency 'rack-test',           '~> 0.6.1'
  s.add_development_dependency 'ruby-debug-wrapper',  '~> 0.0.1'

  s.require_path = 'lib'

  s.files        = Dir.glob("lib/**/*") +
                   Dir.glob("bin/**/*") +
                   Dir.glob("config/**/*") +
                   Dir.glob("site_templates/**/*") +
                   %w(Gemfile config.ru locomotive_editor.gemspec)
end
