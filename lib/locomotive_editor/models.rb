require 'locomotive_editor/models/base'

Dir[File.join(File.dirname(__FILE__), 'models', '*.rb')].each { |lib| require lib }