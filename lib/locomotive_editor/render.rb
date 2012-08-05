module Sinatra
  module Templates

    def locomotive(template = nil, options = {}, locals = {})
      LocomotiveEditor::Logger.info "rendering page at \"#{template || request.fullpath}\" (#{Time.now})"

      LocomotiveEditor::Models::Base.reload!
      _render_locomotive_page
    end

    private

    def _render_locomotive_page
      @page = lookup_locomotive_page

      if @page.nil?
        redirect_to_404_locomotive_page
        return
      end

      redirect @page.redirect_url and return if @page.redirect?

      content = @page.render(build_locomotive_context)

      selector = build_locomotive_site_selector

      if selector.blank?
        content
      else
        if content.index('</body>')
          content.gsub('</body>', selector + '</body>')
        else
          content << selector
        end
      end
    end

    def lookup_locomotive_page(path = nil)
      path ||= locomotive_page_path

      if path != 'index'
        path = LocomotiveEditor::Models::Page.path_combinations(path)
      end

      LocomotiveEditor::Logger.info "retrieving: #{path.inspect} / #{::I18n.locale} / #{params.inspect}"

      page = LocomotiveEditor::Models::Site.first.lookup_page(path, false)

      if page && page.templatized? # try templatized page
        @content_instance = page.fetch_content_type_entry(path.first)

        page = nil if @content_instance.nil?
      end

      page
    end

    def redirect_to_404_locomotive_page
      unless request.path == '/404'
        if LocomotiveEditor::Models::Site.first.default_locale.to_s == ::I18n.locale.to_s
          redirect '/404'
        else
          redirect File.join('/', ::I18n.locale.to_s, '404')
        end
      end
    end

    def locomotive_page_path
      path = params[:splat].first.clone
      path.gsub!(/\.[a-zA-Z][a-zA-Z0-9]{2,}$/, '')
      path.gsub!(/^\//, '')
      path.gsub!(/^[A-Z]:\//, '') # windows platforms (bug: https://github.com/locomotivecms/engine/issues/221)

      # extract the site locale
      if path =~ /^(#{LocomotiveEditor::Models::Site.first.locales.join('|')})+(\/|$)/
        ::I18n.locale = $1
        path.gsub!($1 + $2, '')
      end

      path = 'index' if path.blank?

      path
    end

    def build_locomotive_context
      safe_flash = flash.dup
      safe_flash.delete_if { |k, v| %w{site page contents current_page}.include?(k) }

      assigns = {
        'site'              => LocomotiveEditor::Models::Site.first,
        'page'              => @page,
        'contents'          => LocomotiveEditor::Liquid::Drops::Contents.new,
        'models'            => LocomotiveEditor::Liquid::Drops::Contents.new,
        'current_page'      => params[:page],
        'path'              => request.path,
        'fullpath'          => request.fullpath,
        'url'               => request.url,
        'params'            => self.params,
        'now'               => Time.now.utc,
        'today'             => Date.today
      }.merge(safe_flash)

      assigns.merge!(LocomotiveEditor.settings['context_assign_extensions'] || {})

      if @page.templatized? # add instance from content type
        assigns['content_instance'] = @content_instance
        assigns[@page.content_type.slug.singularize] = @content_instance # just here to help to write readable liquid code
      end

      registers = {
        :site   => LocomotiveEditor::Models::Site.first,
        :page   => @page
      }

      ::Liquid::Context.new({}, assigns, registers, true)
    end

    def build_locomotive_site_selector
      sites = LocomotiveEditor.sites

      return '' if sites.size < 2 || LocomotiveEditor.settings[:hide_sites_selector]

      %{
        <select id="site-select" style="position: absolute; top: 3px; right: 0px; z-index: 9999;">
          #{sites.map{ |s| %{<option value='#{s.folder}'#{ s.folder == LocomotiveEditor.current_site ? ' selected' : ''}>#{s.name}</option>} } }
        </select>
        <script>
          var selector = document.getElementById('site-select');
          selector.onchange = function() {
            window.location = '/reload/' + selector.value
          }
        </script>
      }
    end

    def decode_callback_url(url)
      (url || '').gsub('&#x2F;', '/')
    end

  end
end