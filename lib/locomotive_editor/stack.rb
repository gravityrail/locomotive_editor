$:.unshift File.dirname(__FILE__)

LocomotiveEditor::Logger.info '...loading core extensions'
require 'locomotive_editor/core_ext'

LocomotiveEditor::Logger.info '...loading other extensions'
require 'locomotive_editor/dragonfly_ext'

LocomotiveEditor::Logger.info "...loading models"
require 'locomotive_editor/models'

LocomotiveEditor::Logger.info "...loading liquid"
require 'locomotive_editor/liquid'

LocomotiveEditor::Logger.info "...loading httparty module"
require 'locomotive_editor/httparty'

LocomotiveEditor::Logger.info "...loading locomotive rendering module"
require 'locomotive_editor/template_reader'
require 'locomotive_editor/render'

LocomotiveEditor::Logger.info "...loading sinatra app"
require 'locomotive_editor/sinatra_app'
