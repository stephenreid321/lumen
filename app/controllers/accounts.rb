ActivateApp::App.controller do
        
  get '/sign_in' do
    erb :'accounts/sign_in'
  end  
  
  post '/accounts/forgot_password' do
    if @account = Account.find_by(email: /^#{params[:email]}$/i)
      @account.password = generate_password(8)
      @account.password_confirmation = @account.password
      @account.save!
         
      Mail.defaults do
        delivery_method :smtp, {
          :address => ENV['NOREPLY_SERVER'],
          :port => ENV['NOREPLY_PORT'].to_i,
          :authentication => ENV['NOREPLY_AUTHENTICATION'],
          :enable_ssl => (ENV['NOREPLY_SSL'] == 'true'),
          :user_name => ENV['NOREPLY_USERNAME'],
          :password => ENV['NOREPLY_PASSWORD']
        }
      end
      mail = Mail.new(
        :to => @account.email,
        :from => "#{ENV['NOREPLY_NAME']} <#{ENV['NOREPLY_ADDRESS']}>",
        :subject => "New password",
        :body => %Q{
Hi #{@account.name.split(' ').first},
   
Someone (hopefully you) requested a new password on #{ENV['DOMAIN']}.

Your new password is: #{@account.password}

You can sign in at http://#{ENV['DOMAIN']}/sign_in.

Best,
#{ENV['NOREPLY_SIG']}
        }
      )
      mail.deliver! 
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
        @provider = Account.provider_object(env['omniauth.auth']['provider'])
        Connection.find_by(provider: @provider.display_name, provider_uid: env['omniauth.auth']['uid']).try(:account)
      end
      if current_account # already signed in            
        if account # already connected
          flash[:error] = "Someone's already connected to that account!"
        else # connect; Account never reaches here
          flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Connected!"
          current_account.connections.build(provider: @provider.display_name, provider_uid: env['omniauth.auth']['uid'], omniauth_hash: env['omniauth.auth'])
          current_account.picture_url = @provider.image.call(env['omniauth.auth']) unless current_account.picture
          current_account.save
        end
        redirect '/account/edit'
      else # not signed in
        if account # sign in
          SignIn.create(account: account)
          session['account_id'] = account.id
          flash[:notice] = "Signed in!"
          if account.sign_ins.count == 1
            redirect '/account/edit'
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
  
  get '/account/:provider/use_picture' do
    protected!
    @provider = Account.provider_object(params[:provider])
    @account = current_account
    @account.picture_url = @provider.image.call(@account.connections.find_by(provider: @provider.display_name).omniauth_hash)
    if @account.save
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Grabbed your picture!"
      redirect '/account/edit'
    else
      flash.now[:error] = "<strong>Hmm.</strong> There was a problem grabbing your picture."
      erb :'accounts/build'
    end
  end   
  
  get '/account/:provider/disconnect' do
    protected!
    @provider = Account.provider_object(params[:provider])    
    @account = current_account
    if @account.connections.find_by(provider: @provider.display_name).destroy
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Disconnected!"
      redirect '/account/edit'
    else
      flash.now[:error] = "<strong>Oops.</strong> The disconnect wasn't successful."
      erb :'accounts/build'
    end
  end      
  
  get '/account/edit' do
    protected!
    @account = current_account
    erb :'accounts/build'
  end
  
  post'/account/edit' do
    protected!
    @account = current_account
    if @account.update_attributes(params[:account])      
      flash[:notice] = "<strong>Great!</strong> Your account was updated successfully."
      if @account.sign_ins.count == 1
        redirect '/'
      else
        redirect '/account/edit'
      end
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/build'
    end
  end
  
  get '/sign_out' do
    session.clear
    redirect '/'
  end
  
  get '/accounts/results' do
    scope = params[:scope]
    scope_id = params[:scope_id]
    @o = (params[:o] ? params[:o] : 'date').to_sym
    @name = params[:name]
    @exp = params[:exp]
    @org = params[:org]
    @q = []
    @q << {:name => /#{@name}/i} if @name
    @q << {:expertise => /#{@exp}/i} if @exp    
    @q << {:id.in => Affiliation.where(organisation_id: Organisation.find_by(name: @org)).only(:account_id).map(&:account_id)} if @org        
    @accounts = case scope
    when 'network'
      current_account.network
    when 'group'
      group = Group.find(scope_id)
      group.members
    when 'conversation'
      conversation = Conversation.find(scope_id)
      conversation.participants
    when 'organisation'
      organisation = Organisation.find(scope_id)
      organisation.members
    when 'sector'
      sector = Sector.find(scope_id)
      sector.members
    end 
    @accounts = @accounts.and(@q)
    @accounts = case @o
    when :name
      @accounts.order_by(:name.asc)
    when :date
      @accounts.order_by(:created_at.desc)
    when :updated
      @accounts.order_by(:updated_at.desc)
    end
    @accounts = @accounts.per_page(10).page(params[:page])
    partial :'accounts/results'
  end
  
  get '/accounts/:id' do
    protected!
    @account = Account.find(params[:id])
    erb :'accounts/account'
  end  
  
end