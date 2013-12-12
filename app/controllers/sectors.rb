ActivateApp::App.controllers do
  
  get '/sectors' do
    sign_in_required!
    @sectors = Sector.all.sort_by { |sector| sector.sectorships.count }.reverse
    erb :'sectors/index'
  end
  
  get '/sectors/:id' do
    sign_in_required!
    @sector = Sector.find(params[:id])
    erb :'sectors/sector'
  end  
  
end