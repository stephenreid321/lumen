module OmniAuth
  module Strategies
    class Account
      include OmniAuth::Strategy
      
      option :sign_in, '/sign_in'
      
      def request_phase
        redirect options.sign_in
      end

      def callback_phase
        return fail!(:invalid_credentials) unless account
        super
      end

      uid { account.uid }
      info { account.info }
      
      def account
        @account ||= ::Account.authenticate(request['email'], request['password'])
      end      

    end
  end
end
