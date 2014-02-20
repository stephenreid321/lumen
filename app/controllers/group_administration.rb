Lumen::App.controllers do
  
  get '/groups/:slug/check' do
    site_admins_only!
    @group = Group.find_by(slug: params[:slug]) || not_found
    @group.check!
  end   
  
  get '/groups/:slug/edit' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    erb :'groups/build'
  end
  
  post '/groups/:slug/edit' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    if @group.update_attributes(params[:group])
      flash[:notice] = "<strong>Great!</strong> The group was updated successfully."
      redirect "/groups/#{@group.slug}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the group from being saved."
      erb :'groups/build'
    end    
  end   
  
  get '/groups/:slug/members' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @view = params[:view] ? params[:view].to_sym : :admins
    @memberships = case @view
    when :admins
      @group.memberships.where(:role => 'admin')
    when :others
      @group.memberships.where(:role => 'member')
    when :never_signed_in
      @group.memberships.select { |membership| membership.account.sign_ins.count == 0 }
    when :no_picture
      @group.memberships.select { |membership| membership.account.picture.nil? }   
    when :no_affiliations
      @group.memberships.select { |membership| membership.account.affiliations.count == 0 }          
    when :notification_level_none
      @group.memberships.where(:notification_level => 'none')
    when :connected_to_twitter
      @group.memberships.select { |membership| membership.account.connections.find_by(provider: 'Twitter') }
    when :geocoding_failed
      @group.memberships.select { |membership| membership.account.location and !membership.account.coordinates }
    when :requests
      @group.membership_requests # quacks like a membership
    end
    @memberships = case @view
    when :connected_to_twitter
      @memberships.sort_by { |membership| membership.account.connections.find_by(provider: 'Twitter').created_at }.reverse
    else
      @memberships.sort_by { |membership| membership.account.name }
    end
    erb :'group_administration/members'
  end
   
  get '/groups/:slug/remove_member/:account_id' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.destroy
    flash[:notice] = "#{@membership.account.name} was removed from the group"
    redirect back
  end 
  
  get '/groups/:slug/make_admin/:account_id' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.update_attribute(:role, 'admin')
    flash[:notice] = "#{@membership.account.name} was made an admin"
    redirect back
  end   
  
  get '/groups/:slug/unadmin/:account_id' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.update_attribute(:role, 'member')
    flash[:notice] = "#{@membership.account.name}'s admin rights were revoked"
    redirect back
  end   

  get '/groups/:slug/set_notification_level/:account_id' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.update_attribute(:notification_level, params[:level])
    flash[:notice] =  "#{@membership.account.name}'s notification options were updated"
    redirect back
  end   
  
  post '/groups/:slug/invite' do 
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    notices = []
    data = params[:data] || "#{params[:name]}\t#{params[:email]}"
    data.split("\n").reject { |line| line.blank? }.each { |line|
      name, email = line.split("\t")
      if !email
        notices << "Please provide an email address for #{name}"
        next
      end
      name.strip!
      email.strip!    
      @extra = ''
      
      if !(@account = Account.find_by(email: /^#{Regexp.escape(email)}$/i))        
        @account = Account.new({
            :name => name,
            :password => Account.generate_password(8),
            :email => email
          })
        @account.password_confirmation = @account.password
        if @account.save
          @extra = " with the email address #{@account.email} and the password #{@account.password}"
        else
          notices << "Failed to create an account for #{email} - is this a valid email address?"
          next
        end
      end
      if @group.memberships.find_by(account: @account)
        notices << "#{email} is already a member of this group."
        next
      else
        @membership = @group.memberships.build :account => @account
        @membership.role = 'admin' if params[:role] == 'admin'
        @membership.save
      
        group = @group # instance var not available in defaults block
        Mail.defaults do
          delivery_method :smtp, group.smtp_settings
        end      
      
        mail = Mail.new(
          :to => @account.email,
          :from => "#{@group.slug} <#{@group.email('-noreply')}>",
          :subject => "#{current_account.name.split(' ').first} added you to the '#{@group.slug}' group on #{ENV['SITE_NAME_SHORT']}",
          :body => erb(:'emails/invite', :layout => false)
        )
        mail.deliver!
        notices << "#{email} was added to the group."
      end
    }
    flash[:notice] = notices.join('<br />') if !notices.empty?
    redirect back
  end
  
  get '/groups/:slug/reminder' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    membership = @group.memberships.find_by(account_id: params[:account_id])
    @account = membership.account
    @issue = case params[:issue].to_sym
    when :never_signed_in
      "signed in to complete your profile"
    when :no_affiliations
      "provided your organisational affiliations"
    when :no_picture
      "uploaded a profile picture"
    end

    group = @group # instance var not available in defaults block
    Mail.defaults do
      delivery_method :smtp, group.smtp_settings
    end        
    
    mail = Mail.new(
      :to => @account.email,
      :from => "#{@group.slug} <#{@group.email('-noreply')}>",
      :cc => current_account.email,
      :subject => "A reminder from #{current_account.name} to complete your #{ENV['SITE_NAME_SHORT']} profile",
      :body => erb(:'emails/reminder', :layout => false)
    )
    mail.deliver!  
    membership.update_attribute(:reminder_sent, Time.now)
    redirect back
  end
          
  get '/groups/:slug/didyouknows' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!       
    erb :'group_administration/didyouknows'
  end  
  
  post '/groups/:slug/didyouknows/add' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @group.didyouknows.create :body => params[:body]
    redirect back
  end    
  
  get '/groups/:slug/didyouknows/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @group.didyouknows.find(params[:id]).destroy
    redirect back
  end 
  
  get '/groups/:slug/process_membership_request/:id' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    membership_request = @group.membership_requests.find(params[:id])    
    @group.memberships.create(:account => membership_request.account) if params[:accept]
    membership_request.destroy
    redirect back
  end
      
end