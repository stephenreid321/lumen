Lumen::App.controllers do
  
  get '/wall' do
    sign_in_required!
    @wall_posts = current_account.wall_posts.order_by(:created_at.desc)
    @wall_posts = @wall_posts.per_page(10).page(params[:page])    
    if request.xhr?
      partial :'wall/wall'
    else
      redirect "/?tab=wall"
    end     
  end
  
  post '/wall/new' do
    flash[:notice] = 'Please select a group'
    redirect "/?tab=wall"
  end
  
  get '/groups/:slug/wall' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @wall_posts = @group.wall_posts.order_by(:created_at.desc)
    @wall_posts = @wall_posts.per_page(10).page(params[:page])
    if request.xhr?
      partial :'wall/wall'
    else
      redirect "/groups/#{@group.slug}?tab=wall"
    end  
  end  
  
  get  '/groups/:slug/wall/:id' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @wall_post = @group.wall_posts.find(params[:id])
    partial :'wall/wall_post', :locals => {:wall_post => @wall_post}, :layout => true
  end
  
  get  '/groups/:slug/wall/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @group.wall_posts.find(params[:id]).destroy    
    flash[:notice] = 'The wall post was removed.'
    redirect (params[:from_home] ?  "/wall" : "/groups/#{@group.slug}/wall")
  end  
  
  post '/groups/:slug/wall/new' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @wall_post = @group.wall_posts.build(params[:wall_post])    
    @wall_post.account = current_account
    @wall_post.save
    redirect (params[:from_home] ?  "/wall" : "/groups/#{@group.slug}/wall")
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