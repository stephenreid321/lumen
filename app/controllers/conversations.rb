Lumen::App.controllers do
  
  get '/groups/:slug/conversations' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required! unless @group.public?
    @conversations = @group.visible_conversations
    @q = params[:q] if params[:q]        
    if @q
      if @q.starts_with?('slug:')
        @conversations = @conversations.where(:slug => @q.split('slug:').last)        
      else            
        q = []
        q << {:body => /#{Regexp.escape(@q)}/i }
        q << {:conversation_id.in => Conversation.where(:subject => /#{Regexp.escape(@q)}/i).pluck(:id)}
        q << {:account_id.in => Account.where(:name => /#{Regexp.escape(@q)}/i).pluck(:id)}
        conversation_posts = @group.visible_conversation_posts.or(q)
        @conversations = @conversations.where(:id.in => conversation_posts.pluck(:conversation_id))
      end
    end    
    @conversations = @conversations.order_by(:updated_at.desc).per_page(ENV['WALL_STYLE_CONVERSATIONS'] ? 5 : 10).page(params[:page])            
    if current_account and ENV['WALL_STYLE_CONVERSATIONS']
      @conversations.each { |conversation|
        conversation.visible_conversation_posts.each { |conversation_post|
          conversation_post.conversation_post_read_receipts.create(account: current_account, web: true)
        }
      }
    end      
    if request.xhr?
      partial :'conversations/conversations'
    else
      redirect "/groups/#{@group.slug}?#{request.query_string}"
    end
  end
  
  get '/conversations/new' do
    sign_in_required!
    erb :'conversations/build'
  end
  
  get '/groups/:slug/conversations/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @conversations = @group.conversations.build
    erb :'conversations/build'
  end  
  
  post '/groups/:slug/conversations/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @conversation = @group.conversations.build(params[:conversation])
    @conversation.body ||= ''
    @conversation.account = current_account
    if @conversation.save
      @conversation_post = @conversation.visible_conversation_posts.first
      @conversation_post.send_notifications!
      redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the conversation from being created."
      erb :'conversations/build'      
    end
  end   
      
  get '/conversations/:slug' do    
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    redirect "/groups/#{@conversation.group.slug}/conversations?q=slug:#{params[:slug]}" if ENV['WALL_STYLE_CONVERSATIONS']
    membership_required!(@conversation.group) unless @conversation.group.public?
    @membership = @conversation.group.memberships.find_by(account: current_account)
    if @conversation.hidden
      flash[:notice] = "That conversation is hidden."
      redirect "/groups/#{@conversation.group.slug}"
    else
      if current_account
        @conversation.visible_conversation_posts.each { |conversation_post|
          conversation_post.conversation_post_read_receipts.create(account: current_account, web: true)
        }
      end
      @title = @conversation.subject
      erb :'conversations/conversation'
    end
  end
  
  post '/conversations/:slug' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    membership_required!(@conversation.group)
    @membership = @conversation.group.memberships.find_by(account: current_account)
    @conversation_post = @conversation.conversation_posts.build(params[:conversation_post])
    @conversation_post.account = current_account
    if @conversation_post.save
      @conversation_post.send_notifications!
      redirect "/conversations/#{@conversation.slug}#conversation-post-#{@conversation_post.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the post from being created."
      erb :'conversations/conversation'      
    end
  end
  
  get '/conversations/:slug/approve' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.update_attribute(:approved, true)
    @conversation.update_attribute(:hidden, false)
    @conversation.conversation_posts.first.send_notifications!(force: true)
    flash[:notice] = "The conversation was approved."
    redirect back
  end    
  
  get '/conversations/:slug/disapprove' do
    @conversation = Conversation.find_by(slug: params[:slug]) || not_found
    group_admins_only!(@conversation.group)
    @conversation.update_attribute(:approved, false)
    flash[:notice] = "The conversation was kept hidden."
    redirect back
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
    @conversation.visible_conversation_posts.find(params[:id]).update_attribute(:hidden, true)
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
  
  get '/conversation_posts/:id/like' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])
    membership_required!(@conversation_post.conversation.group)
    @conversation_post.likes.create(account: current_account)
    flash[:notice] = "You liked the post by #{@conversation_post.account.name}"
    redirect "/conversations/#{@conversation_post.conversation.slug}" 
  end
    
  get '/conversation_posts/:id/remove_like' do
    sign_in_required!
    @conversation_post = ConversationPost.find(params[:id])
    membership_required!(@conversation_post.conversation.group)
    @conversation_post.likes.find_by(account: current_account).destroy
    flash[:notice] = 'Your like was removed'
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
    redirect "/conversations/#{@conversation_post.conversation.slug}#conversation-post-#{@conversation_post.id}" unless request.xhr?    
    @accounts = Account.where(:id.in => @conversation_post.conversation_post_read_receipts.pluck(:account_id))
    @accounts = @accounts.order(:name.asc).per_page(params[:per_page] || 50).page(params[:page])
    @title = "People who read this"
    partial :'accounts/results_compact', :layout => 'modal'
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