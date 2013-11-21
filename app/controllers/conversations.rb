ActivateApp::App.controllers do
  
  post '/groups/:slug/new_conversation' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    @conversation = @group.conversations.create!(subject: params[:subject])
    @conversation_post = @conversation.conversation_posts.create!(:body => params[:body], :account => current_account)        
    if params[:attachment]
      @conversation_post.attachments.create! :file => params[:attachment], :file_name => request.POST['attachment'][:filename]
    end    
    @conversation_post.send_notifications!
    redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
  end   
    
  get '/conversations/:slug' do
    protected!
    @conversation = Conversation.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Conversation, :slug => params[:slug])
    erb :'conversations/conversation'
  end
  
  post '/conversations/:slug/post' do
    protected!
    @conversation = Conversation.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Conversation, :slug => params[:slug])
    @conversation_post = @conversation.conversation_posts.create!(:body => params[:body], :account => current_account)
    if params[:attachment]
      @conversation_post.attachments.create! :file => params[:attachment], :file_name => request.POST['attachment'][:filename]
    end
    @conversation_post.send_notifications!
    redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
  end
  
  get '/conversations/:slug/destroy' do
    protected!
    @conversation = Conversation.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Conversation, :slug => params[:slug])
    @conversation.destroy
    flash[:notice] = "The conversation was deleted."
    redirect "/groups/#{@conversation.group.slug}"
  end  
    
end