Lumen::App.controllers do
  
  get '/groups/:slug/spaces' do
    redirect "/groups/#{params[:slug]}/map"
  end

  get '/spaces/new' do
    sign_in_required!
    erb :'spaces/build'
  end 
    
  get '/groups/:slug/spaces/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @space = @group.spaces.build
    erb :'spaces/build'
  end    
  
  post '/groups/:slug/spaces/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @space = @group.spaces.build(params[:space])
    @space.account = current_account
    if @space.save  
      flash[:notice] = "<strong>Great!</strong> The space was created successfully."
      redirect "/groups/#{@group.slug}/spaces/#{@space.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the space from being saved."
      erb :'spaces/build'
    end
  end
     
  get '/groups/:slug/spaces/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @space = @group.spaces.find(params[:id]) || not_found
    erb :'spaces/build'
  end
  
  post '/groups/:slug/spaces/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @space = @group.spaces.find(params[:id]) || not_found
    if @space.update_attributes(params[:space])
      flash[:notice] = "<strong>Great!</strong> The space was updated successfully."
      redirect "/groups/#{@group.slug}/spaces/#{@space.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the space from being saved."
      erb :'spaces/build'
    end
  end   
  
  get '/groups/:slug/spaces/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @space = @group.spaces.find(params[:id]) || not_found
    @space.destroy
    flash[:notice] = 'The space was removed.'
    redirect "/groups/#{@group.slug}/map"
  end  
  
  get '/groups/:slug/spaces/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required! unless @group.publicly_viewable?
    @space = @group.spaces.find(params[:id]) || not_found
    erb :'spaces/space'
  end    
              
end