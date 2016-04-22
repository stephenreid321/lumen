Lumen::App.controllers do
  
  get '/sectors' do
    sign_in_required!
    @sectors = current_account.network_sectors.sort_by { |sector| sector.sectorships.count }.reverse
    erb :'sectors/index'
  end
    
  get '/sectors/:id' do
    sign_in_required!
    @sector = Sector.find(params[:id])
    @title = @sector.name
    erb :'sectors/sector'
  end  
  
end