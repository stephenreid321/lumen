Lumen::App.controllers do
    
  get '/groups/:slug/classifieds' do
    redirect '/classifieds'
  end    
  
  get '/classifieds' do
    sign_in_required!
    @classifieds = current_account.classifieds    
    @classifieds = @classifieds.where(group_id: params[:group_id]) if params[:group_id]
    @classifieds = @classifieds.where(description: /#{Regexp.escape(params[:q])}/i) if params[:q]
    @classifieds = @classifieds.order_by(:created_at.desc)
    if request.xhr?
      partial :'classifieds/classifieds'
    else
      erb :'classifieds/classifieds'
    end
  end
  
  get '/classifieds/new' do
    sign_in_required!
    @title = 'Make a request/offer'
    partial :'groups/pick', :locals => {:collection => 'classifieds'}, :layout => (:modal if request.xhr?)
  end
  
  get '/groups/:slug/classifieds/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @classified = @group.classifieds.build
    erb :'classifieds/build'
  end  
        
  post '/groups/:slug/classifieds/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @classified = @group.classifieds.build(params[:classified])    
    @classified.account = current_account
    if @classified.save
      flash[:notice] = "<strong>Great!</strong> The request/offer was added successfully."
      redirect "/groups/#{@group.slug}/classifieds"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the request/offer from being saved."
      erb :'classifieds/build'      
    end
  end
  
  get  '/classifieds/:id/destroy' do    
    @classified = Classified.find(params[:id])
    membership_required!(@classified.group)
    @classified.destroy    
    flash[:notice] = 'The classified was removed.'
    redirect back
  end    
    
end