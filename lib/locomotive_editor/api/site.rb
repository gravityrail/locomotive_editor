module LocomotiveEditor
  module Api

    class Site < Base

      def show
        OpenStruct.new(self.class.get('/current_site.json'))
      end

    end

  end
end