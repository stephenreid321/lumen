Lumen::App.controllers do
  
  get '/calendar', :provides => [:html, :ics] do    
    sign_in_required!
    case content_type   
    when :ics      
      Event.ical(current_account)
    when :html      
      partial :'events/calendar', :locals => {:calendar_path => '/calendar'}, :layout => true
    end     
  end
        
  get '/calendar/feed' do
    sign_in_required!
    Event.json(current_account, params[:start], params[:end])
  end  
  
  get '/calendar/add' do
    sign_in_required!
    erb :'events/build'
  end  
  
  get '/calendar/:id/edit' do
    @event = current_account.events.find(params[:id]) || not_found
    membership_required!(@event.group)
    redirect "/groups/#{@event.group.slug}/calendar/#{@event.id}/edit"
  end   
  
  get '/groups/:slug/calendar', :provides => [:html, :ics] do    
    @group = Group.find_by(slug: params[:slug])    
    membership_required!
    case content_type   
    when :ics
      Event.ical(@group)
    when :html     
      erb :'groups/calendar'
    end    
  end   

  get '/groups/:slug/calendar/feed', :provides => :json do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    Event.json(@group, params[:start], params[:end])
  end  
    
  get '/groups/:slug/calendar/add' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @event = @group.events.build
    erb :'events/build'
  end
  
  post '/groups/:slug/calendar/add' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @event = @group.events.build(params[:event])    
    @event.account = current_account
    if @event.save  
      flash[:notice] = "<strong>Great!</strong> The event was created successfully."
      if @event.start_conversation == '1'
        conversation = @event.group.conversations.create!(subject: "New event: #{@event.name}")
        conversation_post = conversation.conversation_posts.create!(
          :body => %Q{<h2><a href="http://#{ENV['DOMAIN']}/groups/#{@group.slug}/calendar/#{@event.id}">#{@event.name}</a></h2>#{partial('events/summary', :locals => {:event => @event})}},
          :account => @event.account)
        conversation_post.send_notifications!  
      end
      redirect "/groups/#{@group.slug}/calendar/#{@event.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the event from being saved."
      erb :'events/build'
    end
  end   
    
  get '/groups/:slug/calendar/:id/edit' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    erb :'events/build'
  end
  
  post '/groups/:slug/calendar/:id/edit' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    if @event.update_attributes(params[:event])
      flash[:notice] = "<strong>Great!</strong> The event was updated successfully."
      redirect "/groups/#{@group.slug}/calendar/#{@event.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the event from being saved."
      erb :'events/build'
    end
  end 
  
  get '/groups/:slug/calendar/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    @event.destroy    
    redirect "/groups/#{@group.slug}/calendar/"
  end 
  
  get '/groups/:slug/calendar/:id' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    erb :'events/event'
  end  
  
  get '/groups/:slug/calendar/:id/summary' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @event = @group.events.find(params[:id]) || not_found
    partial :'events/summary', :locals => {:event => @event, :read_more => true}
  end    
  
end