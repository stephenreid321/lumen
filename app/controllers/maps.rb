Lumen::App.controllers do
      
  get '/groups/:slug/map' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?          
    if request.xhr?
      points = []
      points += @group.memberships.map(&:account).map(&:affiliations).flatten.map(&:organisation).uniq if params[:organisations]
      points += @group.memberships.map(&:account) if params[:accounts]      
      if params[:map_only]
        partial :'maps/map', :locals => {:points => points}
      else
        partial :'maps/map_form', :locals => {:points => points}
      end
    else    
      redirect "/groups/#{@group.slug}?tab=map"
    end  
  end  
              
end