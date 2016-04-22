Lumen::App.controllers do
  
  get '/organisations' do
    sign_in_required!
    erb :'organisations/index'
  end
    
  get '/organisations/results', :provides => [:json, :html] do
    sign_in_required!
    @o = (params[:o] ? params[:o] : 'date').to_sym
    @organisation_id = params[:organisation_id]
    @sector_id = params[:sector_id]
    @organisations = current_account.network_organisations
    @q = []
    @q << {:id => @organisation_id} if @organisation_id
    @q << {:id.in => Sectorship.where(sector_id: @sector_id).pluck(:organisation_id)} if @sector_id    
    @organisations = @organisations.and(@q)
    case content_type      
    when :json
      case params[:rtype].to_sym
      when :organisation
        {
          results: (results = @organisations; results = results.where(:name => /#{Regexp.escape(params[:q])}/i) if params[:q]; results.map { |organisation| {id: organisation.id.to_s, text: organisation.name} })
        }
      when :sector
        {
          results: (results = Sector.where(:id.in => Sectorship.where(:organisation_id.in => @organisations.pluck(:id)).pluck(:sector_id)); results = results.where(:name => /#{Regexp.escape(params[:q])}/i) if params[:q]; results.map { |sector| {id: sector.id.to_s, text: sector.name} })
        }          
      end.to_json   
    when :html
      @organisations = case @o
      when :name
        @organisations.order_by(:name.asc)
      when :date
        @organisations.order_by(:updated_at.desc)
      end      
      @organisations = @organisations.per_page(10).page(params[:page])
      partial :'organisations/results'
    end    
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