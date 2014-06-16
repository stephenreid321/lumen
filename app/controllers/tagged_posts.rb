Lumen::App.controllers do
  
  get '/tagged_posts' do
    sign_in_required!
    @tagged_posts = current_account.tagged_posts.order_by(:created_at.desc)
    @tagged_posts = @tagged_posts.per_page(10).page(params[:page])    
    if request.xhr?
      partial :'tagged_posts/tagged_posts'
    else
      redirect "/#tagged_posts-tab"
    end     
  end
    
  get '/groups/:slug/tagged_posts' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @tagged_posts = @group.tagged_posts.order_by(:created_at.desc)
    @tagged_posts = @tagged_posts.per_page(10).page(params[:page])
    if request.xhr?
      partial :'tagged_posts/tagged_posts'
    else
      redirect "/groups/#{@group.slug}#tagged_posts-tab"
    end  
  end  
    
  post '/tagged_posts/new' do
    if params[:tags]
      @tagged_post = TaggedPost.new(params[:tagged_post])    
      params[:tags].each { |tag|
        @tagged_post.tagged_post_tagships.build(account_tag_name: tag)
      }
      @tagged_post.account = current_account
      @tagged_post.save
    else
      flash[:error] = 'Please pick one or more tags'
    end
    redirect "#{back}#tagged_posts-tab"
  end
  
  get  '/tagged_posts/:id' do
    @tagged_post = TaggedPost.find(params[:id])
    partial :'tagged_posts/tagged_post', :locals => {:tagged_post => @tagged_post}, :layout => true
  end
  
  get  '/tagged_posts/:id/destroy' do
    TaggedPost.find(params[:id]).destroy    
    flash[:notice] = 'The post was removed.'
    redirect back
  end    
    
end