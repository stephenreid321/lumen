Lumen::App.controllers do
  
  post '/groups/:slug/new_conversation' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @conversation = @group.conversations.create!(subject: params[:subject])
    @conversation_post = @conversation.conversation_posts.create!(:body => params[:body], :account => current_account)        
    if params[:attachment]
      @conversation_post.attachments.create! :file => params[:attachment]
    end    
    @conversation_post.send_notifications!
    redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
  end   
    
  get '/conversations/:slug' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    if @conversation.hidden
      flash[:notice] = "That conversation has been deleted."
      redirect "/groups/#{@conversation.group.slug}"
    else
      erb :'conversations/conversation'
    end
  end
  
  post '/conversations/:slug/post' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    @conversation_post = @conversation.conversation_posts.create!(:body => params[:body], :account => current_account)
    if params[:attachment]
      @conversation_post.attachments.create! :file => params[:attachment]
    end
    @conversation_post.send_notifications!
    redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
  end
  
  get '/conversations/:slug/hide' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.update_attribute(:hidden, true)
    flash[:notice] = "The conversation was hidden."
    redirect "/groups/#{@conversation.group.slug}"
  end  
  
  get '/conversations/:slug/hide_post/:id' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.conversation_posts.find(params[:id]).update_attribute(:hidden, true)
    flash[:notice] = "The post was hidden."
    redirect "/conversations/#{@conversation.slug}"
  end    
    
end