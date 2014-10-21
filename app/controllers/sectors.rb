Lumen::App.controllers do
  
  get '/sectors' do
    sign_in_required!
    @sectors = current_account.network_sectors.sort_by { |sector| sector.sectorships.count }.reverse
    erb :'sectors/index'
  end
  
  get '/sectors/cleanup' do
    site_admins_only!
    Sector.all.each { |sector|
      sector.destroy if sector.sectorships.count == 0      
    }
    redirect '/sectors'
  end  
  
  get '/sectors/:id' do
    sign_in_required!
    @sector = Sector.find(params[:id])
    erb :'sectors/sector'
  end  
  
end