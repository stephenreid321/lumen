Lumen::App.controllers do

  get '/analytics' do
    site_admins_only!      
    @conversation_threshold = ENV['SITEWIDE_ANALYTICS_CONVERSATION_THRESHOLD'].to_i     
    @models = [ConversationPost, Conversation, Account, Event, PageView].select { |model|
      model.count > 0
    }.select { |model|
      if model == Conversation
        Conversation.all.any? { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
      else
        true
      end
    }      
    @collections = @models.map { |model|
      resources = model.order_by(:created_at.asc) 
      if model == Conversation
        resources = resources.select { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
      end
      resources
    }            
    erb :'analytics/analytics'
  end

  get '/groups/:slug/analytics' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!      
    @conversation_threshold = @group.analytics_conversation_threshold
    @collection_names = [:conversation_posts, :conversations, :memberships, :events].select { |collection_name|
      @group.send(collection_name).count > 0
    }.select { |collection_name|
      if collection_name == :conversations
        @group.send(:conversations).all.any? { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
      else
        true
      end
    }
      
    @collections = @collection_names.map { |collection_name|
      resources = @group.send(collection_name).order_by(:created_at.asc) 
      if collection_name == :conversations
        resources = resources.select { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
      end
      resources
    }
      
    erb :'analytics/analytics'
  end 
  
end