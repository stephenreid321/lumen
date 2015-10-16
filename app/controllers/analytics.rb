Lumen::App.controllers do
  
  get '/analytics' do
    redirect '/analytics/unique_visitors'
  end

  get '/analytics/cumulative_totals' do
    site_admins_only!      
    @models = [ConversationPost, Account, Event].select { |model| model.count > 0 }
    @collections = @models
    @from = params[:from] ? Date.parse(params[:from]) : 1.month.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
    erb :'analytics/cumulative_totals'
  end

  get '/groups/:slug/analytics' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    group_admins_only!      
    @collection_names = [:conversation_posts, :memberships, :events].select { |collection_name| @group.send(collection_name).count > 0 }      
    @collections = @collection_names.map { |collection_name| @group.send(collection_name) }      
    @from = params[:from] ? Date.parse(params[:from]) : 1.month.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today    
    erb :'analytics/cumulative_totals'
  end 
  
  get '/analytics/unique_visitors' do
    site_admins_only!  
    @from = params[:from] ? Date.parse(params[:from]) : 1.month.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today        
    erb :'analytics/unique_visitors'    
  end  
  
  get '/analytics/page_views' do
    site_admins_only!  
    @from = params[:from] ? Date.parse(params[:from]) : 1.month.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today    
    erb :'analytics/page_views'    
  end
  
end