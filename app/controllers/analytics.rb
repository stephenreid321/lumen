Lumen::App.controllers do

  get '/analytics' do
    site_admins_only!      
    @models = [ConversationPost, Conversation, Account, Event, PageView]
    @collections = @models.map { |model| model.order_by(:created_at.asc) }            
    erb :'analytics/analytics'
  end

  get '/groups/:slug/analytics' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!      
    @collection_names = [:conversation_posts, :conversations, :memberships, :events].select { |collection_name| @group.send(collection_name).count > 0 }      
    @collections = @collection_names.map { |collection_name| @group.send(collection_name).order_by(:created_at.asc) }      
    erb :'analytics/analytics'
  end 
  
end