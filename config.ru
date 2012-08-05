require 'locomotive_editor'
require 'locomotive_editor/stack'

LocomotiveEditor.require_ext_loader

LocomotiveEditor.reload_site

if LocomotiveEditor::DragonflyExt.setup!
  use Rack::Cache, :verbose => false
  use Dragonfly::Middleware, :images
end

use Rack::Session::Cookie,
  :key          => 'rack.session',
  :domain       => '0.0.0.0',
  :path         => '/',
  :expire_after => 2592000, # In seconds
  :secret       => 'asupersecretkey'

run LocomotiveEditor::SinatraApp
