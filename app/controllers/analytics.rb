Lumen::App.controllers do
  
  before do
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
  end
  
  get '/analytics' do
    redirect '/analytics/unique_visitors'
  end

  get '/analytics/cumulative_totals' do
    site_admins_only!      
    @collections = [ConversationPost, Account, Event]
    erb :'analytics/cumulative_totals'
  end
  
  get '/analytics/unique_visitors' do
    site_admins_only!  
    erb :'analytics/unique_visitors'    
  end  
  
  get '/analytics/page_views' do
    site_admins_only!
    erb :'analytics/page_views'    
  end
  
  get '/analytics/groups' do
    site_admins_only!
    erb :'analytics/groups'
  end
  
  get '/analytics/organisations' do
    site_admins_only!
    erb :'analytics/organisations'
  end  
  
end