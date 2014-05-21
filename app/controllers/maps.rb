Lumen::App.controllers do
  
  get '/map' do
    sign_in_required!
    if request.xhr?
      points = []
      points += current_account.network.map(&:affiliations).flatten.map(&:organisation).uniq if params[:organisations]
      points += current_account.network if params[:accounts] or !params[:map_only]
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
    if request.xhr?
      points = []
      points += @group.memberships.map(&:account).map(&:affiliations).flatten.map(&:organisation).uniq if params[:organisations]
      points += @group.members if params[:accounts] or !params[:map_only]
      if params[:map_only]
        partial :'maps/map', :locals => {:points => points}
      else
        partial :'maps/map_form', :locals => {:points => points}
      end
    else    
      redirect "/groups/#{@group.slug}#map-tab"
    end  
  end  
              
end