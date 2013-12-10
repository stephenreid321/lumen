ActivateApp::App.controllers do
    
  get '/groups/check' do
    if params[:slug]
      @group = Group.find_by(slug: params[:slug])
      @group.check!
    else
      Group.check!
    end
    Time.now.to_s
  end
                    
  get '/groups/:slug' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @current_membership = @group.memberships.find_by(account: current_account)
    if !@current_membership
      flash[:error] = "You're not a member of that group!"
      redirect '/'
    end
    @conversations = @group.conversations
    @q = params[:q] if params[:q]        
    if @q
      q = []
      ConversationPost.fields.each { |fieldstring, fieldobj|
        if fieldobj.type == String and !fieldstring.starts_with?('_')          
          q << {fieldstring.to_sym => /#{@q}/i }
        elsif fieldstring.ends_with?('_id') && fieldstring != '_id' && Object.const_defined?((assoc_name = ConversationPost.fields[fieldstring].metadata.class_name))          
          q << {"#{assoc_name.underscore}_id".to_sym.in => assoc_name.constantize.where(assoc_name.constantize.send(:lookup) => /#{@q}/i).only(:_id).map(&:_id) }
        end          
      }   
      @conversation_posts = @group.conversation_posts.or(q)
      @conversations = @conversations.where(:id.in => @conversation_posts.only(:conversation_id).map(&:conversation_id))
    end                         
    @conversations = @conversations.per_page(10).page(params[:page])
    erb :'groups/group'
  end  
        
  get '/groups/:slug/members' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    if @group.memberships.find_by(account: current_account).admin?
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
      end
      @memberships = @memberships.sort_by { |membership| membership.account.name }
      erb :'groups/members'
    else
      flash[:error] = "You're not an admin of that group!"
      redirect "/groups/#{@group.slug}"
    end
  end
   
  get '/groups/:slug/remove_member/:account_id' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.destroy
    flash[:notice] = "#{@membership.account.name} was removed from the group"
    redirect back
  end 
  
  get '/groups/:slug/make_admin/:account_id' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.update_attribute(:role, 'admin')
    flash[:notice] = "#{@membership.account.name} was made an admin"
    redirect back
  end   
  
  get '/groups/:slug/unadmin/:account_id' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @membership = @group.memberships.find_by(account_id: params[:account_id])
    @membership.update_attribute(:role, 'member')
    flash[:notice] = "#{@membership.account.name}'s admin rights were revoked"
    redirect back
  end   

  get '/groups/:slug/set_notification_level/:account_id/:level' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
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
    protected!    
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
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
    
      if !(account = Account.find_by(email: /^#{Regexp.escape(email)}$/i))        
        account = Account.new({
            :name => name,
            :password => generate_password(8),
            :email => email
          })
        account.password_confirmation = account.password
        if account.save
          extra = " with the email address #{account.email} and the password #{account.password}"
        else
          notices << "Failed to create an account for #{email} - is this a valid email address?"
          next
        end
      end
      if @group.memberships.find_by(account: account)
        notices << "#{email} is already a member of this group."
        next
      else
        @membership = @group.memberships.build :account => account
        @membership.role = 'admin' if params[:role] == 'admin'
        @membership.notification_level = 'none' if params[:notification_level] != 'each'
        @membership.save
      
        group = @group # instance var not available in defaults block
        Mail.defaults do
          delivery_method :smtp, { :address => group.smtp_server, :port => group.smtp_port, :authentication => group.smtp_authentication, :enable_ssl => group.smtp_ssl, :user_name => group.smtp_username, :password => group.smtp_password }
        end      
      
        mail = Mail.new(
          :to => account.email,
          :from => "#{@group.smtp_name} <#{@group.smtp_address}>",
          :subject => "#{current_account.name.split(' ').first} added you to the '#{@group.slug}' group on #{ENV['SITE_NAME_SHORT']}",
          :body => %Q{
Hi #{account.name.split(' ').first},
   
#{current_account.name} added you to the '#{@group.slug}' group on #{ENV['SITE_NAME_DEFINITE']}.

You can sign in at http://#{ENV['DOMAIN']}/sign_in#{extra}.

Best,
#{@group.smtp_sig}
          }
        )
        mail.deliver!
        notices << "#{email} was added to the group."
      end
    }
    flash[:notice] = notices.join('<br />') if !notices.empty?
    redirect back
  end
  
  get '/groups/:slug/reminder' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    membership = @group.memberships.find_by(account_id: params[:account_id])
    account = membership.account
    issue = case params[:issue].to_sym
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
      :to => account.email,
      :from => "#{@group.smtp_name} <#{@group.smtp_address}>",
      :cc => current_account.email,
      :subject => "A reminder from #{current_account.name} to complete your #{ENV['SITE_NAME_SHORT']} profile",
      :body => %Q{
Hi #{account.name.split(' ').first},
   
#{current_account.name} noticed that you haven't yet #{issue} on #{ENV['DOMAIN']}.

Well-maintained profiles help build a stronger community. Will you spare a minute to provide the missing details?

You can sign in at http://#{ENV['DOMAIN']}/sign_in.

Best,
#{@group.smtp_sig}
      }
    )
    mail.deliver!  
    membership.update_attribute(:reminder_sent, Time.now)
    redirect back
  end
  
  get '/groups/:slug/join' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @group.memberships.create :account => current_account
    redirect "/groups/#{@group.slug}"
  end
  
  get '/groups/:slug/leave' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @group.memberships.find_by(:account => current_account).destroy
    redirect "/groups/#{@group.slug}"
  end  
  
  get '/groups/:slug/notification_level/:level' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @group.memberships.find_by(account: current_account).update_attribute(:notification_level, params[:level]) if Membership.notification_levels.include? params[:level]
    flash[:notice] = 'Notification options updated!'
    redirect "/groups/#{@group.slug}"
  end    
  
  get '/groups/:slug/analytics' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])      
    if @group.memberships.find_by(account: current_account).admin?
      
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
      
      erb :'groups/analytics'
    else
      flash[:error] = "You're not an admin of that group!"
      redirect "/groups/#{@group.slug}"
    end
  end  
  
  get '/groups/:slug/news_summaries' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])      
    if @group.memberships.find_by(account: current_account).admin?           
      erb :'groups/news_summaries'
    else
      flash[:error] = "You're not an admin of that group!"
      redirect "/groups/#{@group.slug}"
    end
  end  
  
  post '/groups/:slug/news_summaries/add' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])              
    @group.news_summaries.create :title => params[:title], :newsme_username => params[:newsme_username]
    redirect back
  end    
  
  get '/groups/:slug/news_summaries/:id/destroy' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])              
    @group.news_summaries.find(params[:id]).destroy
    redirect back
  end     
  
  get '/groups/:slug/didyouknows' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])      
    if @group.memberships.find_by(account: current_account).admin?           
      erb :'groups/didyouknows'
    else
      flash[:error] = "You're not an admin of that group!"
      redirect "/groups/#{@group.slug}"
    end
  end  
  
  post '/groups/:slug/didyouknows/add' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])              
    @group.didyouknows.create :body => params[:body]
    redirect back
  end    
  
  get '/groups/:slug/didyouknows/:id/destroy' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])              
    @group.didyouknows.find(params[:id]).destroy
    redirect back
  end  
  
end