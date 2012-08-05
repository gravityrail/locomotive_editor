require File.join(File.dirname(__FILE__), 'commands/base.rb')

%w(create generate help list run upgrade list_templates push).each do |name|
  require File.join(File.dirname(__FILE__), "commands/#{name}.rb")
end