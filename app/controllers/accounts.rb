Lumen::App.controllers do
  
  get '/accounts/new' do
    site_admins_only!
    @account = Account.new
    @account.welcome_email_subject = "You were added to #{ENV['SITE_NAME_DEFINITE']}"
    @account.welcome_email_body = %Q{Hi [firstname],
<br /><br />
You were added to the groups [group_list] on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
[sign_in_details]}
    erb :'accounts/new'      
  end  
    
  post '/accounts/new' do
    site_admins_only!
    @account = Account.new(params[:account])
    password = Account.generate_password(8)
    @account.password = password
    @account.password_confirmation = password
    if @account.save
      flash[:notice] = 'The account was created successfully'
           
      Mail.defaults do
        delivery_method :smtp, Account.smtp_settings
      end
      
      sign_in_details = ''
      if @account.confirm_memberships.to_i == 0
        sign_in_details << "You need to sign in to start receiving email notifications. "
      end       
      sign_in_details << "Sign in at http://#{ENV['DOMAIN']}/sign_in with the email address #{@account.email} and the password #{password}"
               
      b = @account.welcome_email_body
      .gsub('[firstname]',@account.name.split(' ').first)
      .gsub('[group_list]',@account.groups.map(&:slug).to_sentence)
      .gsub('[sign_in_details]', sign_in_details)      
            
      mail = Mail.new
      mail.to = @account.email
      mail.from = "#{ENV['SITE_NAME']} <#{ENV['HELP_ADDRESS']}>"
      mail.subject = @account.welcome_email_subject
      mail.html_part do
        content_type 'text/html; charset=UTF-8'
        body b
      end
      mail.deliver 
    
      redirect back
    else
      flash.now[:error] = 'Some errors prevented the account from being saved'
      erb :'accounts/new'      
    end
  end    
    
  get '/accounts/results' do
    sign_in_required!
    scope = params[:scope]
    scope_id = params[:scope_id]
    @o = (params[:o] ? params[:o] : 'date').to_sym
    @name = params[:name]    
    @organisation_name = params[:organisation_name]
    @account_tag_name = params[:account_tag_name]
    @accounts = case scope
    when 'network'
      current_account.network
    when 'group'
      group = Group.find(scope_id)
      membership_required!(group) unless group.public?
      group.members
    when 'conversation'
      conversation = Conversation.find(scope_id)
      membership_required!(conversation.group) unless conversation.group.public?
      conversation.participants
    when 'organisation'
      organisation = Organisation.find(scope_id)
      organisation.members
    when 'sector'
      sector = Sector.find(scope_id)
      sector.members
    end 
    @q = []    
    @q << {:id.in => Affiliation.where(:organisation_id.in => Organisation.where(:name => /#{Regexp.escape(@organisation_name)}/i).pluck(:id)).pluck(:account_id)} if @organisation_name
    @q << {:id.in => AccountTagship.where(:account_tag_id.in => AccountTag.where(:name => /#{Regexp.escape(@account_tag_name)}/i).pluck(:id)).pluck(:account_id)} if @account_tag_name    
    @accounts = @accounts.and(@q)    
    @accounts = @accounts.or({:name => /#{Regexp.escape(@name)}/i}, {:name_transliterated => /#{Regexp.escape(@name)}/i}) if @name            
    @accounts = case @o
    when :name
      @accounts.order_by(:name.asc)
    when :date
      @accounts.order_by(:created_at.desc)
    when :updated
      @accounts.order_by([:has_picture.desc, :updated_at.desc])
    end      
    @accounts = @accounts.per_page(params[:per_page] || 8).page(params[:page])
    partial :'accounts/results', locals: {full_width: params[:full_width]}
  end  
    
  get '/accounts/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    @shared_conversations = current_account.visible_conversation_posts.where(account_id: @account.id).order_by(:created_at.desc).limit(10).map(&:conversation).uniq if current_account
    @title = @account.name
    erb :'accounts/account'
  end    
              
end