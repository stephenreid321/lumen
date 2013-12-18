ActivateApp::App.controller do
    
  get '/accounts/results' do
    sign_in_required!
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
      @accounts.order_by([:updated_profile.desc, :updated_at.desc])
    end
    @accounts = @accounts.per_page(10).page(params[:page])
    partial :'accounts/results'
  end  
  
  get '/accounts/:id' do
    sign_in_required!
    @account = Account.find(params[:id])
    erb :'accounts/account'
  end    
    
  get '/account/edit' do
    sign_in_required!
    @account = current_account
    erb :'accounts/build'
  end
  
  post'/account/edit' do
    sign_in_required!
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
  
  get '/account/:provider/use_picture' do
    sign_in_required!
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
    sign_in_required!
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

  get '/account/week' do
    sign_in_required!    
    @from = params[:from] ? params[:from].to_date : 1.week.ago.to_date
    @to = params[:to] ? params[:to].to_date : Date.today
    
    @top_stories = NewsSummary.top_stories(current_account.news_summaries, @from, @to)[0..4]
    @accounts = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).select { |account| account.updated_profile && account.picture }
    @conversations = current_account.conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).select { |conversation| conversation.conversation_posts.count >= 3 }
    @events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1)
        
    erb :'groups/week'    
  end
        
end