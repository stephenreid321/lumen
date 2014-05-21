Lumen::App.controllers do
  
  get '/map' do
    sign_in_required!
    if request.xhr?
      points = []
      points += current_account.network.map(&:affiliations).flatten.map(&:organisation).uniq if params[:organisations]
      points += current_account.network if params[:accounts]
      if params[:map_only]
        partial :'maps/map', :locals => {:points => points}
      else
        partial :'maps/map_form', :locals => {:points => points}
      end
    else    
      redirect "/#map-tab"
    end  
  end   
      
  get '/groups/:slug/map' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?   
    @membership = @group.memberships.find_by(account: current_account)
    if request.xhr?
      points = []
      points += @group.memberships.map(&:account).map(&:affiliations).flatten.map(&:organisation).uniq if params[:organisations]
      points += @group.spaces if params[:spaces]
      points += @group.members if params[:accounts]
      if params[:map_only]
        partial :'maps/map', :locals => {:points => points}
      else
        partial :'maps/map_form', :locals => {:points => points}
      end
    else    
      redirect "/groups/#{@group.slug}#map-tab"
    end  
  end  
  
  post '/groups/:slug/map/spaces/new' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @space = @group.spaces.build(name: params[:name], description: params[:description], link: params[:link], coordinates: [params[:lng], params[:lat]], account: current_account)      
    if !@space.save
      flash[:error] = "Please place a marker and provide a name"
    end
    redirect "/groups/#{@group.slug}#map-tab"
  end
  
  get '/groups/:slug/map/spaces/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @group.spaces.find(params[:id]).destroy
    flash[:notice] = 'The space was removed.'
    redirect "/groups/#{@group.slug}#map-tab"
  end  
              
end