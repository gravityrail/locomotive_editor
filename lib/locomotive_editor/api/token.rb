module LocomotiveEditor
  module Api

    class Token

      include HTTParty

      def self.get_one(uri, email, password)
        self.base_uri uri

        response = post(
          '/tokens.json',
          :body => {
            :email    => email,
            :password => password
          }
        )

        if response.code == 200
          response['token']
        else
          raise response['message']
        end
      end

    end

  end
end