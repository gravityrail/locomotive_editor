require 'RedCloth'

module LocomotiveEditor
  module Liquid
    module Filters
      module Text

        def textile(input)
          ::RedCloth.new(input).to_html
        end

      end

      ::Liquid::Template.register_filter(Text)

    end
  end
end
