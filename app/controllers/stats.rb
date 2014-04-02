Lumen::App.controllers do

  get '/groups/:slug/stats' do
    sign_in_required!
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    redirect "/groups/#{@group.slug}/request_membership" if !@membership and @group.closed?    
    membership_required! if @group.secret?
      
    @c = {}
    @cp = {}      
    @group.conversations.each { |conversation|
      conversation.conversation_posts.where(:hidden.ne => true).order_by(:created_at.asc).each_with_index { |conversation_post, i|
        if i == 0
          @c[conversation_post.account] = [] if !@c[conversation_post.account]
          @c[conversation_post.account] << conversation_post
        end
        @cp[conversation_post.account] = [] if !@cp[conversation_post.account]
        @cp[conversation_post.account] << conversation_post
      }
    }    
    
    @e = {}
    @group.events.each { |event|
      @e[event.account] = [] if !@e[event.account]
      @e[event.account] << event
    }    
    
    if request.xhr?
      partial :'stats/stats'
    else
      redirect "/groups/#{@group.slug}?tab=stats"
    end
  end
  
end