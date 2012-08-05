require 'locomotive_editor/site_templates/template'
require 'locomotive_editor/site_templates/manager'

Dir[File.join(File.dirname(__FILE__), '../../site_templates', '*.rb')].each { |f| require f }