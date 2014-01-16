Lumen::App.controller do
  
  get '/me' do
    sign_in_required!
    redirect "/accounts/#{current_account.id}"
  end
   
  get '/me/edit' do
    sign_in_required!
    @account = current_account
    erb :'accounts/build'
  end
  
  post '/me/edit' do
    sign_in_required!
    @account = current_account
    if @account.update_attributes(params[:account])      
      flash[:notice] = "<strong>Great!</strong> Your account was updated successfully."
      if @account.sign_ins.count == 1
        redirect '/'
      else
        redirect '/me/edit'
      end
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/build'
    end
  end
  
  get '/me/:provider/use_picture' do
    sign_in_required!
    @provider = Account.provider_object(params[:provider])
    @account = current_account
    @account.picture_url = @provider.image.call(@account.connections.find_by(provider: @provider.display_name).omniauth_hash)
    if @account.save
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Grabbed your picture!"
      redirect '/me/edit'
    else
      flash.now[:error] = "<strong>Hmm.</strong> There was a problem grabbing your picture."
      erb :'accounts/build'
    end
  end   
  
  get '/me/:provider/disconnect' do
    sign_in_required!
    @provider = Account.provider_object(params[:provider])    
    @account = current_account
    if @account.connections.find_by(provider: @provider.display_name).destroy
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Disconnected!"
      redirect '/me/edit'
    else
      flash.now[:error] = "<strong>Oops.</strong> The disconnect wasn't successful."
      erb :'accounts/build'
    end
  end  
  
  get '/me/news' do
    partial :'news/summaries', :locals => {:news_summaries => current_account.news_summaries, :date => NewsSummary.date + params[:d].to_i}
  end
                
  get '/me/review' do
    sign_in_required!    
    @from = 1.week.ago.to_date + 7*params[:w].to_i
    @to = Date.today + 7*params[:w].to_i
    @upcoming = @to + 7
    
    @top_stories = Hash[current_account.news_summaries.map { |news_summary| [news_summary, news_summary.top_stories(@from, @to)[0..2]] }]
    @accounts = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).select { |account| account.affiliated && account.picture }
    @conversations = current_account.conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.conversation_posts.count >= 3 }
    @new_events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @to).order_by(:start_time.asc)
    @period_events = current_account.events.where(:start_time.gte => @to).where(:start_time.lt => @upcoming+1).order_by(:start_time.asc)
    
    if request.xhr?
      partial :'review/review', :locals => {:from => @from, :to => @to, :top_stories => @top_stories, :accounts => @accounts, :conversations => @conversations, :new_events => @new_events, :period_events => @period_events}
    else
      erb :'groups/review'
    end
  end
    
end