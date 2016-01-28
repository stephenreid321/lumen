Lumen::App.controllers do
  
  get '/groups/:slug/events' do
    redirect '/events'
  end  
  
  get '/events', :provides => [:html, :ics] do    
    sign_in_required!
    case content_type   
    when :ics      
      Event.ical(current_account)
    when :html   
      case params[:view]
      when 'calendar'
        erb :'events/calendar'    
      else
        erb :'events/events'    
      end
    end     
  end
        
  get '/events/feed' do
    sign_in_required!
    Event.json(current_account, params[:start], params[:end])
  end  
  
  get '/events/new' do
    sign_in_required!
    erb :'events/build'
  end  
  
  get '/events/:id/edit' do
    @event = current_account.events.find(params[:id]) || not_found
    membership_required!(@event.group)
    redirect "/groups/#{@event.group.slug}/events/#{@event.id}/edit"
  end   
      
  get '/groups/:slug/events/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @event = @group.events.build
    erb :'events/build'
  end
  
  post '/groups/:slug/events/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @event = @group.events.build(params[:event])    
    @event.account = current_account
    if @event.save  
      flash[:notice] = "<strong>Great!</strong> The event was created successfully."
      if @event.start_conversation == '1'
        conversation = @event.group.conversations.create!(subject: "New event: #{@event.name}", account: current_account)
        conversation_post = conversation.conversation_posts.create!(
          :body => %Q{<h2><a href="http://#{ENV['DOMAIN']}/groups/#{@group.slug}/events/#{@event.id}">#{@event.name}</a></h2>#{partial('events/summary', :locals => {:event => @event})}},
          :account => @event.account)
        conversation_post.send_notifications!  
      end
      redirect "/groups/#{@group.slug}/events/#{@event.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the event from being saved."
      erb :'events/build'
    end
  end   
    
  get '/groups/:slug/events/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    erb :'events/build'
  end
  
  post '/groups/:slug/events/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    if @event.update_attributes(params[:event])
      flash[:notice] = "<strong>Great!</strong> The event was updated successfully."
      redirect "/groups/#{@group.slug}/events/#{@event.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the event from being saved."
      erb :'events/build'
    end
  end 
  
  get '/groups/:slug/events/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    @event.destroy    
    redirect "/groups/#{@group.slug}/events/"
  end 
  
  get '/groups/:slug/events/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required! unless @group.public?
    @event = @group.events.find(params[:id]) || not_found
    erb :'events/event'
  end  
  
  get '/groups/:slug/events/:id/minimal' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required! unless @group.public?
    @event = @group.events.find(params[:id]) || not_found
    partial :'events/minimal', :locals => {:event => @event, :read_more => true}
  end    
  
end