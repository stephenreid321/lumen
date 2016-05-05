Lumen::App.controllers do
  
  get '/organisations' do
    sign_in_required!
    erb :'organisations/index'
  end
    
  get '/organisations/results' do
    sign_in_required!
    @o = (params[:o] ? params[:o] : 'date').to_sym
    @name = params[:name]
    @sector_name = params[:sector_name]
    @organisations = current_account.network_organisations    
    @q = []
    @q << {:id.in => Sectorship.where(:sector_id.in => Sector.where(:name => /#{Regexp.escape(@sector_name)}/i).pluck(:id)).pluck(:organisation_id)} if @sector_name
    @organisations = @organisations.and(@q)
    @organisations = @organisations.where(:name => /#{Regexp.escape(@name)}/i) if @name    
    @organisations = case @o
    when :name
      @organisations.order_by(:name.asc)
    when :date
      @organisations.order_by(:updated_at.desc)
    end      
    @organisations = @organisations.per_page(10).page(params[:page])
    partial :'organisations/results'    
  end  
  
  get '/organisations/:id' do
    sign_in_required!
    @organisation = Organisation.find(params[:id]) || not_found
    @title = @organisation.name
    erb :'organisations/organisation'
  end
       
  get '/organisations/:id/edit' do
    sign_in_required!
    @organisation = Organisation.find(params[:id]) || not_found
    erb :'organisations/build'
  end
  
  post '/organisations/:id/edit' do
    sign_in_required!
    @organisation = Organisation.find(params[:id]) || not_found
    if @organisation.update_attributes(params[:organisation])      
      flash[:notice] = "<strong>Great!</strong> The organisation was updated successfully."
      redirect "/organisations/#{@organisation.id}/edit"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the organisation from being saved."
      erb :'organisations/build'
    end
  end  
  
  get '/organisations/:id/destroy' do
    sign_in_required!
    @organisation = Organisation.find(params[:id]) || not_found
    @organisation.destroy    
    redirect '/organisations'
  end   
  
end