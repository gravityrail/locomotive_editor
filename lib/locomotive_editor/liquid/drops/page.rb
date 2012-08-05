module LocomotiveEditor
  module Liquid
    module Drops
      class Page < Base

        delegate :title, :slug, :fullpath, :parent, :depth, :seo_title, :meta_description, :meta_keywords, :to => '_source'

        def children
          @children ||= liquify(*@_source.children)
        end

        def published?
          @_source.published?
        end

      end
    end
  end
end
