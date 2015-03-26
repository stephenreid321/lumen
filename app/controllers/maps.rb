Lumen::App.controllers do
  
  get '/map' do
    sign_in_required!
    if request.xhr?
      points = []
      if params[:organisations]
        points += current_account.network.map(&:affiliations).flatten.map(&:organisation).uniq
      end
      if params[:spaces]
        spaces = current_account.spaces
        spaces = Space.filtered(spaces, params)
        points += spaces
      end
      if params[:accounts]
        points += current_account.network
      end
      @disable_scrollwheel = true if ENV['STACKED_HOME']
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
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required! unless @group.open?   
    @membership = @group.memberships.find_by(account: current_account)
    @space = @group.spaces.build
    if request.xhr?
      points = []
      if params[:organisations]
        points += @group.members.map(&:affiliations).flatten.map(&:organisation).uniq
      end
      if params[:spaces]
        spaces = @group.spaces
        spaces = Space.filtered(spaces, params)
        points += spaces
      end
      if params[:accounts]
        points += @group.members
      end
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