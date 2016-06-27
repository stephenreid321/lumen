Lumen::App.controllers do
    
  get '/conversation_posts/:id/like' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])
    membership_required!(@conversation_post.conversation.group)
    @conversation_post.likes.create(account: current_account)
    if request.xhr?
      partial :'conversations/like', :locals => {:conversation_post => @conversation_post}
    else
      flash[:notice] = "You liked the post by #{@conversation_post.account.name}"
      redirect "/conversations/#{@conversation_post.conversation.slug}" 
    end
  end
    
  get '/conversation_posts/:id/remove_like' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])
    membership_required!(@conversation_post.conversation.group)
    @conversation_post.likes.find_by(account: current_account).destroy
    if request.xhr?
      partial :'conversations/like', :locals => {:conversation_post => @conversation_post}
    else
      flash[:notice] = 'Your like was removed'
      redirect "/conversations/#{@conversation_post.conversation.slug}" 
    end    
  end 
  
  get '/conversation_posts/:id/likes' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])    
    redirect "/conversations/#{@conversation_post.conversation.slug}#conversation-post-#{@conversation_post.id}" unless request.xhr?    
    @accounts = Account.where(:id.in => @conversation_post.likes.pluck(:account_id))
    @accounts = @accounts.order(:name.asc).per_page(params[:per_page] || 50).page(params[:page])
    @title = "People who liked this"
    partial :'accounts/results_compact', :layout => 'modal'    
  end 
  
end