Lumen::App.controllers do
  
  get '/groups/:slug/conversations' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    redirect "/groups/#{@group.slug}/request_membership" if !@membership and @group.closed?    
    membership_required! if @group.secret?    
    @conversations = @group.conversations.where(:hidden.ne => true)
    @q = params[:q] if params[:q]        
    if @q
      q = []
      q << {:body => /#{@q}/i }
      q << {:conversation_id.in => Conversation.where(:subject => /#{@q}/i).only(:_id).map(&:_id)}
      q << {:account_id.in => Account.where(:name => /#{@q}/i).only(:_id).map(&:_id)}
      conversation_posts = @group.conversation_posts.where(:hidden.ne => true).or(q)
      @conversations = @conversations.where(:id.in => conversation_posts.only(:conversation_id).map(&:conversation_id))
    end                         
    @conversations = @conversations.order_by(:updated_at.desc).per_page(10).page(params[:page])            
    if request.xhr?
      partial :'conversations/conversations'
    else
      redirect "/groups/#{@group.slug}#conversations-tab"
    end
  end
  
  post '/groups/:slug/new_conversation' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    ((flash[:error] = %Q{Please provide a subject and body}) and redirect back) unless (params[:subject] and params[:body])
    @conversation = @group.conversations.create!(subject: params[:subject], account: current_account)
    @conversation_post = @conversation.conversation_posts.create!(:body => params[:body], :account => current_account)        
    if params[:attachment]
      @conversation_post.attachments.create! :file => params[:attachment]
    end    
    @conversation_post.send_notifications!
    redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
  end   
    
  get '/conversations/:slug' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group) unless @conversation.group.open?
    @membership = @conversation.group.memberships.find_by(account: current_account)
    if @conversation.hidden
      flash[:notice] = "That conversation has been removed."
      redirect "/groups/#{@conversation.group.slug}"
    else
      if current_account
        @conversation.conversation_posts.each { |conversation_post|
          conversation_post.conversation_post_read_receipts.create(account: current_account, web: true)
        }
      end
      erb :'conversations/conversation'
    end
  end
  
  post '/conversations/:slug/post' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    ((flash[:error] = %Q{Please provide a body}) and redirect back) unless params[:body]
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
  
  get '/conversations/:slug/mute' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    @conversation.conversation_mutes.create(account: current_account)
    flash[:notice] = "The conversation was muted."
    redirect "/conversations/#{@conversation.slug}"
  end    
  
  get '/conversations/:slug/unmute' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    @conversation.conversation_mutes.find_by(account: current_account).destroy
    flash[:notice] = "The conversation was unmuted."
    redirect "/conversations/#{@conversation.slug}"
  end      
  
  get '/conversation_posts/:id/plus_one' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])
    membership_required!(@conversation_post.conversation.group)
    @conversation_post.plus_ones.create(account: current_account)
    flash[:notice] = "You +1'd the post by #{@conversation_post.account.name}"
    redirect "/conversations/#{@conversation_post.conversation.slug}" 
  end
    
  get '/conversation_posts/:id/remove_plus_one' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])
    membership_required!(@conversation_post.conversation.group)
    @conversation_post.plus_ones.find_by(account: current_account).destroy
    flash[:notice] = 'Your +1 was removed'
    redirect "/conversations/#{@conversation_post.conversation.slug}" 
  end 
  
  get '/conversation_post_bccs/:id/read', :provides => :gif do
    @conversation_post_bcc = ConversationPostBcc.find(params[:id]) || not_found
    @conversation_post_bcc.read_receipt!
    File.open("#{Padrino.root}/app/assets/images/pixel.gif", "r").read
  end
  
  get '/conversation_posts/:id/read_receipts' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])    
    @accounts = Account.where(:id.in => @conversation_post.conversation_post_read_receipts.only(:account_id).map(&:account_id))
    @accounts = @accounts.per_page(params[:per_page] || 10).page(params[:page])
    @title = "People who read this"
    partial :'accounts/results', :layout => 'modal'
  end
  
  get '/conversation_posts/:id/plus_ones' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])    
    @accounts = Account.where(:id.in => @conversation_post.plus_ones.only(:account_id).map(&:account_id))
    @accounts = @accounts.per_page(params[:per_page] || 10).page(params[:page])
    @title = "People who +1'd this"
    partial :'accounts/results', :layout => 'modal'    
  end
    
end