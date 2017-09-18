Lumen::App.controllers do
        
  get '/sign_in' do
    erb :'accounts/sign_in'
  end  
  
  get '/sign_out' do
    session.clear
    redirect '/sign_in'
  end  
  
  post '/accounts/forgot_password' do
    if params[:email] and @account = Account.find_by(email: /^#{Regexp.escape(params[:email])}$/i)
      @account.update_attribute(:password_reset_token, SecureRandom.uuid)
         
      Mail.defaults do
        delivery_method :smtp, Account.smtp_settings
      end
      mail = Mail.new(
        :to => @account.email,
        :from => "#{Config['SITE_NAME']} <#{Config['HELP_ADDRESS']}>",
        :subject => "New password",
        :body => erb(:'emails/forgot_password', :layout => false)
      )
      mail.deliver 
      flash[:notice] = "Further instructions were sent to #{@account.email}"
    else
      flash[:error] = "There's no account registered under that email address. Please contact #{Config['HELP_ADDRESS']} for assistance."
    end
    redirect back
  end
  
  get '/accounts/reset_password/:password_reset_token' do
    if @account = Account.find_by(password_reset_token: params[:password_reset_token])
      erb :'accounts/reset_password'
    else
      flash[:error] = 'That link has expired'
      redirect '/sign_in'      
    end
  end
  
  post '/accounts/reset_password/:password_reset_token' do
    if @account = Account.find_by(password_reset_token: params[:password_reset_token])
      if @account.update_attributes(mass_assigning(params[:account], Account))
        @account.update_attribute(:password_reset_token, nil)
        flash[:notice] = 'Your password was reset. You can sign in below.'
        redirect '/sign_in'
      else
        erb :'accounts/reset_password'
      end
    else
      flash[:error] = 'That link has expired'
      redirect '/sign_in'      
    end
  end
  
  get '/auth/failure' do
    if current_account
      flash[:error] = "There was a problem connecting your account. This can happen sometimes. Give it another whirl."
      refreshParent
    else
      flash.now[:error] = "<strong>Hmm.</strong> There was a problem signing you in."
      erb :'accounts/sign_in'
    end
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
        if @provider # attempt to connect
          if account # already connected
            flash[:error] = "Someone's already connected to that account!"
          else # connect
            current_account.provider_links.build(provider: @provider.display_name, provider_uid: env['omniauth.auth']['uid'], omniauth_hash: env['omniauth.auth'])
            current_account.picture_url = @provider.image.call(env['omniauth.auth']) unless current_account.picture
            if current_account.save
              flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Connected!"
            else
              session[:validate] = true
              flash[:error] = "There are errors with your account that need correcting before making connections."
            end
          end
          refreshParent
        else
          redirect '/'
        end
      else # not signed in
        if account # sign in
          SignIn.create(account: account)
          session[:account_id] = account.id.to_s
          flash[:notice] = "Signed in!"
          if account.sign_ins.count == 1
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