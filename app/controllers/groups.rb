Lumen::App.controllers do
  
  get '/groups/new' do
    ENV['GROUP_CREATION_BY_ADMINS_ONLY'] ? site_admins_only! : sign_in_required!
    @group = Group.new
    erb :'groups/build'
  end
  
  post '/groups/new' do
    ENV['GROUP_CREATION_BY_ADMINS_ONLY'] ? site_admins_only! : sign_in_required!
    @group = Group.new(params[:group])    
    if @group.save  
      flash[:notice] = "<strong>Great!</strong> The group was created successfully."
      @group.memberships.create! :account => current_account, :admin => true, :receive_membership_requests => true
      redirect "/groups/#{@group.slug}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the group from being saved."
      erb :'groups/build'
    end    
  end
  
  get '/groups' do      
    sign_in_required!
    erb :'groups/groups'
  end
                                
  get '/groups/:slug' do    
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    redirect "/groups/#{@group.slug}/request_membership" if !@membership and @group.closed?    
    membership_required! if @group.secret?
    @account = Account.new
    erb :'groups/group'
  end
    
  get '/groups/:slug/members' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required! unless @group.public?
    erb :'groups/members'    
  end
          
  get '/groups/:slug/request_membership' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    redirect back unless @group.closed?    
    (flash[:notice] = "You're already a member of that group" and redirect back) if @group.memberships.find_by(account: current_account)
    (flash[:notice] = "You've already requested membership to that group" and redirect back) if @group.membership_requests.find_by(account: current_account, status: 'pending')
    (flash[:notice] = "You must sign in to request membership" and redirect '/sign_in') if ENV['PRIVATE_NETWORK'] and !current_account and !@group.primary
    @account = Account.new
    erb :'groups/request_membership'
  end

  post '/groups/:slug/request_membership' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    redirect back unless @group.closed?
    if current_account
      @account = current_account
    else           
      if !(@account = Account.find_by(email: /^#{Regexp.escape(params[:account][:email])}$/i))
        @account = Account.new(params[:account])
        @account.password = Account.generate_password(8) # this password is never actually used; it's reset by process_membership_request
        @account.password_confirmation = @account.password 
        if !@account.save
          flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
          halt 400, (erb :'groups/request_membership')
        end
      end
    end    
    
    if @group.memberships.find_by(account: @account)
      flash[:notice] = "You're already a member of that group!"
      redirect back
    elsif @group.membership_requests.find_by(account: @account, status: 'pending')
      flash[:notice] = "You've already requested membership of that group."
      redirect back
    else
      @group.membership_requests.create :account => @account, :status => 'pending', :answers => (params[:answers].each_with_index.map { |x,i| [@group.request_questions_a[i],x] } if params[:answers])
      
      group = @group
      Mail.defaults do
        delivery_method :smtp, group.smtp_settings
      end      
      
      if @group.admins_receiving_membership_requests.count > 0
        mail = Mail.new(
          :to => @group.admins_receiving_membership_requests.map(&:email),
          :from => "#{@group.slug} <#{@group.email('-noreply')}>",
          :subject => "#{@account.name} requested membership of #{@group.slug} on #{ENV['SITE_NAME_SHORT']}",
          :body => erb(:'emails/membership_request', :layout => false)
        )
        mail.deliver   
      end
            
      b = @group.membership_request_thanks_email
      .gsub('[firstname]',@account.name.split(' ').first)   
        
      mail = Mail.new
      mail.to = @account.email
      mail.from = "#{@group.slug} <#{@group.email('-noreply')}>"
      mail.subject = @group.membership_request_thanks_email_subject
      mail.html_part do
        content_type 'text/html; charset=UTF-8'
        body b
      end
      mail.deliver        
      
      flash[:notice] = 'Your request was sent.'
      redirect (current_account ? '/' : '/sign_in')
    end    
  end
  
  get '/groups/:slug/join' do
    @group = Group.find_by(slug: params[:slug]) || not_found    
    redirect back unless @group.public? or @group.open?    
    if current_account
      @account = current_account
    else
      redirect back if !params[:account]
      if !(@account = Account.find_by(email: /^#{Regexp.escape(params[:account][:email])}$/i))   
        @new_account = true
        @account = Account.new(params[:account])
        @account.password = Account.generate_password(8)
        @account.password_confirmation = @account.password
        if !@account.save
          flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
          halt 400, (erb :'groups/group')
        end
      end
    end
      
    if @group.memberships.find_by(account: @account)
      flash[:error] = "#{@account.email} is already a member of this group."
      redirect back
    end
      
    @membership = @group.memberships.create :account => @account
    (flash[:error] = "You've been prevented from joining other groups" and redirect back) unless @membership.persisted?
    
    if @new_account
      SignIn.create(account: @account)
      session[:account_id] = @account.id
      flash[:notice] = %Q{You joined #{@group.slug}!}
      redirect '/me/edit'      
    else
      redirect "/groups/#{@group.slug}"    
    end
  end  
  
  get '/groups/:slug/leave' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @group.memberships.find_by(:account => current_account).destroy
    redirect "/groups/#{@group.slug}"
  end  
  
  get '/groups/:slug/notification_level' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @membership =  @group.memberships.find_by(account: current_account)
    @membership.update_attribute(:notification_level, params[:level]) if Membership.notification_levels.include? params[:level]
    flash[:notice] = 'Notification options updated!'
    redirect "/groups/#{@group.slug}/conversations"
  end   
            
end