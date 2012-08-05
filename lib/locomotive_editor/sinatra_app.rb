require 'sinatra'
require 'sinatra/base'
require 'sinatra/flash'
require 'sass'
require 'compass'
require 'coffee-script'
require 'pistol'

begin
  YAML::ENGINE.yamler = 'syck'
rescue
end

module LocomotiveEditor
  class SinatraApp < Sinatra::Base

    set :public_folder, File.join(LocomotiveEditor.site_root, 'public')

    set :locales, %w(fr en).map { |l| File.join(File.dirname(__FILE__), "/../../config/#{l}.yml") }

    register Sinatra::I18n

    register Sinatra::Flash

    use Pistol, LocomotiveEditor.ext_files do
      reset! and load(__FILE__) && load(LocomotiveEditor.settings[:loader_file])
    end unless LocomotiveEditor.ext_files.empty?

    get '/favicon.ico' do
      ''
    end

    post '/entry_submissions/:slug.html' do
      type = LocomotiveEditor::Models::Site.first.lookup_content_type(params[:slug])
      content = type.add_content(params[:content])

      flash[params[:slug].singularize] = content.safe_attributes

      flash[:errors] = content.errors

      LocomotiveEditor::Logger.info "creating #{content.valid? ? 'valid' : 'invalid'} content: #{content.safe_attributes.inspect}"

      redirect decode_callback_url(content.valid? ? params[:success_callback] : params[:error_callback])
    end

    post '/entry_submissions/:slug.json' do
      type = LocomotiveEditor::Models::Site.first.lookup_content_type(params[:slug])
      content = type.add_content(params[:content])

      content_type :json

      LocomotiveEditor::Logger.info "creating #{content.valid? ? 'valid' : 'invalid'} content: #{content.safe_attributes.inspect}"

      { params[:slug].singularize => content.safe_attributes, :errors => content.errors }.to_json
    end

    get '/reload/:site' do
      LocomotiveEditor.site = params[:site]
      LocomotiveEditor.reload_site
      redirect '/'
    end

    # render SASS/SCSS stylesheets
    get '*.css' do
      content_type 'text/css', :charset => 'utf-8'

      # FIXME: not sure if there is a better way to have both sass and scss
      if File.exists?(File.join(settings.public_folder, request.fullpath + '.scss'))
        scss :"#{request.fullpath}", ::Compass.sass_engine_options
      elsif File.exists?(File.join(settings.public_folder, request.fullpath + '.sass'))
        sass :"#{::Compass.configuration.sass_dir}/#{File.basename(request.fullpath, '.css')}", ::Compass.sass_engine_options
      else
        scss :"#{::Compass.configuration.sass_dir}/#{File.basename(request.fullpath, '.css')}", ::Compass.sass_engine_options
      end
    end

    # render JS CoffeeScript
    get '*.js' do
      content_type 'text/javascript', :charset => 'utf-8'
      coffee :"#{request.fullpath}"
    end

    # render Locomotive pages
    get '*' do
      locomotive # render locomotive page
    end

  end
end