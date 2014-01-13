Lumen::App.controllers do
  
  get '/groups/:slug/check' do
    site_admins_only!
    Group.find_by(slug: params[:slug]).check!
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

  get '/groups/:slug/set_notification_level/:account_id/:level' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.update_attribute(:notification_level, params[:level])
    flash[:notice] = case @membership.notification_level
    when 'none'
      "#{@membership.account.name}'s notifications were turned off"
    when 'each'
      "#{@membership.account.name}'s notifications were turned on"
    end
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
        @membership.notification_level = 'none' if params[:notification_level] != 'each'
        @membership.save
      
        group = @group # instance var not available in defaults block
        Mail.defaults do
          delivery_method :smtp, { :address => group.smtp_server, :port => group.smtp_port, :authentication => group.smtp_authentication, :enable_ssl => group.smtp_ssl, :user_name => group.smtp_username, :password => group.smtp_password }
        end      
      
        mail = Mail.new(
          :to => @account.email,
          :from => "#{@group.smtp_name} <#{@group.smtp_address}>",
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
      delivery_method :smtp, { :address => group.smtp_server, :port => group.smtp_port, :authentication => group.smtp_authentication, :enable_ssl => group.smtp_ssl, :user_name => group.smtp_username, :password => group.smtp_password }
    end        
    
    mail = Mail.new(
      :to => @account.email,
      :from => "#{@group.smtp_name} <#{@group.smtp_address}>",
      :cc => current_account.email,
      :subject => "A reminder from #{current_account.name} to complete your #{ENV['SITE_NAME_SHORT']} profile",
      :body => erb(:'emails/reminder', :layout => false)
    )
    mail.deliver!  
    membership.update_attribute(:reminder_sent, Time.now)
    redirect back
  end
      
  get '/groups/:slug/analytics' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!      
    @conversation_threshold = @group.analytics_conversation_threshold
    @collection_names = [:conversation_posts, :conversations, :memberships, :events].select { |collection_name|
      @group.send(collection_name).count > 0
    }.select { |collection_name|
      if collection_name == :conversations
        @group.send(:conversations).all.any? { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
      else
        true
      end
    }
      
    @collections = @collection_names.map { |collection_name|
      resources = @group.send(collection_name).order_by(:created_at.asc) 
      if collection_name == :conversations
        resources = resources.select { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
      end
      resources
    }
      
    erb :'group_administration/analytics'
  end  
  
  get '/groups/:slug/news_summaries' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    erb :'group_administration/news_summaries'    
  end  
  
  post '/groups/:slug/news_summaries/add' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @group.news_summaries.create :title => params[:title], :newsme_username => params[:newsme_username]
    redirect back
  end    
  
  get '/groups/:slug/news_summaries/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @group.news_summaries.find(params[:id]).destroy
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
  
  get '/groups/:slug/send_review' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    erb :'group_administration/send_review'
  end  
  
  post '/groups/:slug/send_review' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    conversation = @group.conversations.create!(subject: "#{@group.slug}'s week in review")
    conversation_post = conversation.conversation_posts.create!(      
      :body => Mechanize.new.get("http://#{ENV['DOMAIN']}/groups/#{@group.slug}/review?email=true&message=#{params[:message]}&token=#{current_account.generate_secret_token}").content, # slightly mad? but repeating the code in /groups/:slug/review isn't very DRY
      :account => current_account
    )
    conversation_post.send_notifications!
    flash[:notice] = "The review was sent."
    redirect "/groups/#{@group.slug}"
  end    
  
end