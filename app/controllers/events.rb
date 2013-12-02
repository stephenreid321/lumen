ActivateApp::App.controllers do
  
  get '/calendar', :provides => [:html, :ics] do    
    case content_type   
    when :ics      
      Event.ical(Account.find(params[:token])) if params[:token]
    when :html
      protected!
      partial :'events/calendar', :locals => {:calendar_path => '/calendar', :export_path => "/calendar.ics?token=#{current_account.id}" }, :layout => true
    end     
  end
      
  get '/groups/:slug/calendar', :provides => [:html, :ics] do    
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])
    case content_type   
    when :ics
      Event.ical(@group)
    when :html
      protected!
      erb :'groups/calendar'
    end    
  end  
  
  get '/calendar/feed' do
    protected!
    Event.json(current_account, params[:start], params[:end])
  end  

  get '/groups/:slug/calendar/feed', :provides => :json do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    Event.json(@group, params[:start], params[:end])
  end  
  
  get '/calendar/add' do
    protected!
    erb :'events/build'
  end
  
  get '/groups/:slug/calendar/add' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    @event = @group.events.build
    erb :'events/build'
  end
  
  post '/groups/:slug/calendar/add' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    @event = @group.events.build(params[:event])    
    @event.account = current_account
    if @event.save  
      flash[:notice] = "<strong>Great!</strong> The event was created successfully."
      redirect "/groups/#{@group.slug}/calendar/#{@event.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the event from being saved."
      erb :'events/build'
    end
  end   
  
  get '/calendar/:id/edit' do
    protected!
    @event = current_account.events.find(params[:id])
    @group = @event.group
    redirect "/groups/#{@group.slug}/calendar/#{@event.id}/edit"
  end  
  
  get '/groups/:slug/calendar/:id/edit' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    @event = @group.events.find(params[:id])
    erb :'events/build'
  end
  
  post '/groups/:slug/calendar/:id/edit' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    @event = @group.events.find(params[:id])
    if @event.update_attributes(params[:event])
      flash[:notice] = "<strong>Great!</strong> The event was updated successfully."
      redirect "/groups/#{@group.slug}/calendar/#{@event.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the event from being saved."
      erb :'events/build'
    end
  end 
  
  get '/groups/:slug/calendar/:id/destroy' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    @event = @group.events.find(params[:id]).destroy    
    redirect "/groups/#{@group.slug}/calendar/"
  end 
  
  get '/groups/:slug/calendar/:id' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    @event = @group.events.find(params[:id])
    erb :'events/event'
  end  
  
  get '/groups/:slug/calendar/:id/summary' do
    protected!
    @group = Group.find_by(slug: params[:slug]) || raise(Mongoid::Errors::DocumentNotFound.new Group, :slug => params[:slug])    
    @event = @group.events.find(params[:id])
    partial :'events/summary'
  end    
  
end