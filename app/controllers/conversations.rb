Lumen::App.controllers do
  
  post '/groups/:slug/new_conversation' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @conversation = @group.conversations.create!(subject: params[:subject])
    @conversation_post = @conversation.conversation_posts.create!(:body => params[:body], :account => current_account)        
    if params[:attachment]
      @conversation_post.attachments.create! :file => params[:attachment], :file_name => request.POST['attachment'][:filename]
    end    
    @conversation_post.send_notifications!
    redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
  end   
    
  get '/conversations/:slug' do
    @conversation = Conversation.find_by(slug: params[:slug])
    membership_required!(@conversation.group)
    erb :'conversations/conversation'
  end
  
  post '/conversations/:slug/post' do
    @conversation = Conversation.find_by(slug: params[:slug])
    membership_required!(@conversation.group)
    @conversation_post = @conversation.conversation_posts.create!(:body => params[:body], :account => current_account)
    if params[:attachment]
      @conversation_post.attachments.create! :file => params[:attachment], :file_name => request.POST['attachment'][:filename]
    end
    @conversation_post.send_notifications!
    redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
  end
  
  get '/conversations/:slug/destroy' do
    @conversation = Conversation.find_by(slug: params[:slug])
    membership_required!(@conversation.group)
    @conversation.destroy
    flash[:notice] = "The conversation was deleted."
    redirect "/groups/#{@conversation.group.slug}"
  end  
    
end