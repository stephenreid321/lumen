Lumen::App.controllers do
  
  get '/groups/:slug/venues' do
    redirect '/map'
  end

  get '/venues/new' do
    sign_in_required!
    erb :'venues/build'
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
    erb :'venues/venue'
  end    
              
end