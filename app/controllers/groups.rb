Lumen::App.controllers do
  
  get '/groups/new' do
    sign_in_required!
    @group = Group.new
    erb :'groups/build'
  end
  
  post '/groups/new' do
    sign_in_required!
    @group = Group.new(params[:group])    
    if @group.save  
      flash[:notice] = "<strong>Great!</strong> The group was created successfully."
      @group.memberships.create! :account => current_account, :role => 'admin'
      redirect "/groups/#{@group.slug}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the group from being saved."
      erb :'groups/build'
    end    
  end
  
  get '/groups' do
    redirect '/groups/directory'
  end
  
  get '/groups/directory' do
    sign_in_required!
    @groups = Group.all
    erb :'/groups/directory'
  end    
  
  get '/groups/directory/:slug' do
    sign_in_required!
    @group_type = GroupType.find_by(slug: params[:slug])
    @groups = @group_type.groups
    erb :'/groups/directory'
  end  
                          
  get '/groups/:slug' do    
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    redirect "/groups/#{@group.slug}/request_membership" if !@membership and @group.closed?    
    membership_required! if @group.secret?
    erb :'groups/group'
  end
    
  get '/groups/:slug/home' do
    sign_in_required!
    Fragment.find_by(slug: 'home').body
  end
    
  get '/groups/:slug/request_membership' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    not_found if @group.secret?
    erb :'groups/request_membership'
  end

  post '/groups/:slug/request_membership' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    not_found if @group.secret?
    if @group.memberships.find_by(account: current_account)
      flash[:notice] = "You're already a member of that group!"
    elsif @group.membership_requests.find_by(account: current_account)
      flash[:notice] = "You've already requested membership of that group."
    elsif @group.closed?
      @group.membership_requests.create :account => current_account
      
      group = @group
      Mail.defaults do
        delivery_method :smtp, group.smtp_settings
      end      
      
      mail = Mail.new(
        :to => @group.admins.map(&:email),
        :from => "#{@group.slug} <#{@group.email('-noreply')}>",
        :subject => "#{current_account.name} requested membership of #{@group.slug} on #{ENV['SITE_NAME_SHORT']}",
        :body => erb(:'emails/membership_request', :layout => false)
      )
      mail.deliver!      
      
      flash[:notice] = 'Your request was sent.'
    end
    redirect back
  end
  
  get '/groups/:slug/join' do
    @group = Group.find_by(slug: params[:slug]) || not_found    
    @group.memberships.create :account => current_account if @group.open?
    redirect "/groups/#{@group.slug}"    
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
    @group.memberships.find_by(account: current_account).update_attribute(:notification_level, params[:level]) if Membership.notification_levels.include? params[:level]
    flash[:notice] = 'Notification options updated!'
    redirect "/groups/#{@group.slug}"
  end   
          
end