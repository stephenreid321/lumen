Lumen::App.controllers do
  
  get '/accounts/:id/map' do
    sign_in_required!
    @account = Account.find(params[:id])
    partial :'maps/iframe', :locals => {:points => ([@account] + @account.affiliations.map(&:organisation))}
  end    
  
  get '/organisations/:id/map' do
    sign_in_required!
    @organisation = Organisation.find(params[:id])
    partial :'maps/iframe', :locals => {:points => ([@organisation] + @organisation.affiliations.map(&:account))}
  end   
  
  get '/groups/:slug/map' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    if request.xhr?
      partial :'groups/map'
    else    
      erb :'groups/map'  
    end   
  end  
  
  get '/groups/:slug/iframe' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    points = []
    points += @group.memberships.map(&:account).map(&:affiliations).flatten.map(&:organisation).uniq if params[:organisations]
    points += @group.memberships.map(&:account) if params[:accounts]
    if params[:lists]
      params[:lists].each { |id|
        list = @group.lists.find(id)
        points += list.list_items if list
      }
    end
    partial :'maps/iframe', :locals => {:points => points}
  end   
    
  get '/groups/:slug/lists/:id/map' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?  
    @list = @group.lists.find(params[:id])
    partial :'maps/iframe', :locals => {:points =>  @list.list_items}    
  end   
        
end