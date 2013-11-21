ActivateApp::App.controllers do
  
  get '/sectors' do
    protected!
    @sectors = Sector.all.sort_by { |sector| sector.sectorships.count }.reverse
    erb :'sectors/index'
  end
  
  get '/sectors/:id' do
    protected!
    @sector = Sector.find(params[:id])
    erb :'sectors/sector'
  end  
  
end