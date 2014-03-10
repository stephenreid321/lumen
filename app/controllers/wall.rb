Lumen::App.controllers do
  
  get  '/groups/:slug/wall' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @wall_posts = @group.wall_posts.order_by(:created_at.desc)
    if request.xhr?
      partial :'wall/wall'
    else
      erb :'groups/wall'
    end
  end  
  
  get  '/groups/:slug/wall/:id' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @wall_post = @group.wall_posts.find(params[:id])
    erb :'groups/wall'
  end
  
  get  '/groups/:slug/wall/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @group.wall_posts.find(params[:id]).destroy    
    flash[:notice] = 'The wall post was removed.'
    redirect "/groups/#{@group.slug}?tab=wall"
  end  
  
  post '/groups/:slug/wall/new' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @wall_post = @group.wall_posts.build(params[:wall_post])    
    @wall_post.account = current_account
    @wall_post.save
    redirect "/groups/#{@group.slug}?tab=wall"
  end    
  
  get '/wall/opengraph',  :provides => [:html, :json] do    
    sign_in_required!
    @og = WallPost.opengraph(params[:url])
    case content_type   
    when :json   
      @og.to_json
    when :html      
      partial :'wall/opengraph', :locals => {:title => @og[:title], :url => @og[:url], :description => @og[:description], :player => @og[:player], :picture => @og[:picture]}
    end    
  end
  
end