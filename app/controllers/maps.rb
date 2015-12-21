Lumen::App.controllers do
  
  get '/map' do
    sign_in_required!    
    @points = []
    if params[:organisations]
      @points += current_account.network.map(&:affiliations).flatten.map(&:organisation).uniq
    end
    if params[:spaces]
      spaces = current_account.spaces
      spaces = Space.filtered(spaces, params)
      @points += spaces
    end
    if params[:accounts]
      @points += current_account.network
    end
    @disable_scrollwheel = true if ENV['STACKED_HOME']    
    if params[:map_only]
      partial :'maps/map', :locals => {:points => @points}
    else
      erb :'maps/map'
    end
  end   
                    
end