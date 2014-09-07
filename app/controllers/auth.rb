Lumen::App.controllers do
        
  get '/sign_in' do
    erb :'accounts/sign_in'
  end  
  
  get '/sign_out' do
    session.clear
    redirect '/'
  end  
  
  post '/accounts/forgot_password' do
    if params[:email] and @account = Account.find_by(email: /^#{Regexp.escape(params[:email])}$/i)
      @account.password = Account.generate_password(8)
      @account.password_confirmation = @account.password
      @account.save!
         
      Mail.defaults do
        delivery_method :smtp, {
          :address => ENV['VIRTUALMIN_IP'],
          :user_name => ENV['MAIL_DOMAIN'].split('.').first,
          :password => ENV['VIRTUALMIN_PASSWORD'],
          :port => 25,
          :authentication => 'login',
          :enable_starttls_auto => false          
        }
      end
      mail = Mail.new(
        :to => @account.email,
        :from => "#{ENV['NOREPLY_NAME']} <no-reply@#{ENV['MAIL_DOMAIN']}>",
        :subject => "New password",
        :body => erb(:'emails/forgot_password', :layout => false)
      )
      mail.deliver 
      flash[:notice] = "A new password was sent to #{@account.email}"
    else
      flash[:error] = "There's no account registered under that email address. Please contact #{ENV['HELP_ADDRESS']} for assistance."
    end
    redirect '/'
  end
  
  get '/auth/failure' do
    flash.now[:error] = "<strong>Hmm.</strong> There was a problem signing you in."
    erb :'accounts/sign_in'
  end
  
  %w(get post).each do |method|
    send(method, "/auth/:provider/callback") do      
      account = if env['omniauth.auth']['provider'] == 'account'
        Account.find(env['omniauth.auth']['uid'])
      else
        env['omniauth.auth'].delete('extra')
        @provider = Provider.object(env['omniauth.auth']['provider'])
        ProviderLink.find_by(provider: @provider.display_name, provider_uid: env['omniauth.auth']['uid']).try(:account)
      end
      if current_account # already signed in            
        if account # already connected
          flash[:error] = "Someone's already connected to that account!"
        else # connect; Account never reaches here
          flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Connected!"
          current_account.provider_links.build(provider: @provider.display_name, provider_uid: env['omniauth.auth']['uid'], omniauth_hash: env['omniauth.auth'])
          current_account.picture_url = @provider.image.call(env['omniauth.auth']) unless current_account.picture
          current_account.save
        end
        redirect '/me/edit'
      else # not signed in
        if account # sign in
          SignIn.create(account: account)
          session['account_id'] = account.id
          flash[:notice] = "Signed in!"
          if account.sign_ins.count == 1
            account.memberships.where(:status => 'pending').each { |membership| membership.update_attribute(:status, 'confirmed') }
            redirect '/me/edit'
          elsif session[:return_to]
            redirect session[:return_to]
          else
            redirect '/'
          end
        else
          redirect '/auth/failure'
        end
      end
    end
  end
    
end