Lumen::App.controllers do
  
  get '/groups/:slug/venues' do
    redirect '/map'
  end
  
  get '/map' do    
    sign_in_required!  
    if request.xhr?      
      @points = []      
      scope = params[:scope] ? Group.find_by(params[:scope]) : current_account  
      if params[:accounts]
        @points += scope.people
      end
      if params[:events]
        @points += scope.events.future
      end        
      if params[:organisations]
        @points += scope.people.map(&:affiliations).flatten.map(&:organisation).uniq
      end
      if params[:venues]
        venues = scope.venues
        venues = venues.or({:capacity.gte => params[:min_capacity]}, {:capacity => nil}) if params[:min_capacity]        
        venues = venues.where(:accessibility.ne => 'Not accessible') if params[:accessible]
        venues = venues.where(:private => true) if params[:private]
        venues = venues.where(:serves_food => true) if params[:serves_food]
        venues = venues.where(:serves_alcohol => true) if params[:serves_alcohol]
        venues = venues.or({:hourly_cost.lte => params[:max_hourly_cost]}, {:hourly_cost => nil}) if params[:max_hourly_cost]
        @points += venues
      end      
      partial :'maps/map', :locals => {:points => @points}
    else
      erb :'maps/map'
    end
  end  

  get '/venues/new' do
    sign_in_required!
    @title = 'Add a venue'
    partial :'groups/pick', :locals => {:collection => 'venues'}, :layout => (:modal if request.xhr?)
  end 
    
  get '/groups/:slug/venues/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @venue = @group.venues.build
    erb :'venues/build'
  end    
  
  post '/groups/:slug/venues/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @venue = @group.venues.build(params[:venue])
    @venue.account = current_account
    if @venue.save  
      flash[:notice] = "<strong>Great!</strong> The venue was created successfully."
      redirect "/groups/#{@group.slug}/venues/#{@venue.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the venue from being saved."
      erb :'venues/build'
    end
  end
     
  get '/groups/:slug/venues/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @venue = @group.venues.find(params[:id]) || not_found
    erb :'venues/build'
  end
  
  post '/groups/:slug/venues/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @venue = @group.venues.find(params[:id]) || not_found
    if @venue.update_attributes(params[:venue])
      flash[:notice] = "<strong>Great!</strong> The venue was updated successfully."
      redirect "/groups/#{@group.slug}/venues/#{@venue.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the venue from being saved."
      erb :'venues/build'
    end
  end   
  
  get '/groups/:slug/venues/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @venue = @group.venues.find(params[:id]) || not_found
    @venue.destroy
    flash[:notice] = 'The venue was removed.'
    redirect '/map'
  end  
  
  get '/groups/:slug/venues/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required! unless @group.public?
    @venue = @group.venues.find(params[:id]) || not_found
    @title = @venue.name
    erb :'venues/venue'
  end    
              
end