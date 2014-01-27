Lumen::App.controllers do
  
  get '/organisations' do
    sign_in_required!
    erb :'organisations/index'
  end
  
  get '/organisations/results' do
    sign_in_required!
    @o = (params[:o] ? params[:o] : 'date').to_sym
    @name = params[:name]
    @sector = params[:sector]
    @q = []
    @q << {:id.in => [Organisation.find_by(name: @name).id]} if @name
    @q << {:id.in => Sectorship.where(sector_id: Sector.find_by(name: @sector)).only(:organisation_id).map(&:organisation_id)} if @sector
    @organisations = Organisation.all
    @organisations = @organisations.and(@q)
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
    @organisation = Organisation.find(params[:id])
    erb :'organisations/organisation'
  end
  
  get '/organisations/:id/map' do
    sign_in_required!
    @organisation = Organisation.find(params[:id])
    partial :'markers/iframe', :locals => {:points => [@organisation]}
  end      
  
  get '/organisations/:id/edit' do
    sign_in_required!
    @organisation = Organisation.find(params[:id])
    erb :'organisations/build'
  end
  
  post '/organisations/:id/edit' do
    sign_in_required!
    @organisation = Organisation.find(params[:id])
    if @organisation.update_attributes(params[:organisation])      
      flash[:notice] = "<strong>Great!</strong> The organisation was updated successfully."
      redirect "/organisations/#{@organisation.id}/edit"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the organisation from being saved."
      erb :'organisations/build'
    end
  end  
  
end