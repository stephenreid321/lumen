Lumen::App.controllers do
  
  before do
    unless current_account and (current_account.admin? or current_account.translator)
      flash[:notice] = 'You must be a site admin or translator to access that page.'
      request.xhr? ? halt(403, "Not Authorized") : redirect('/')
    end  
  end
  
  get '/translations' do
    erb :translations
  end
  
  post '/translations' do
    params[:translations].each { |language_id, map|
      map.each { |k,v|
        translation = Translation.find_by(language_id: language_id, key: k) || Translation.new(language_id: language_id, key: k)
        translation.value = v
        translation.save
      }
    }
    redirect '/translations'
  end
  
end