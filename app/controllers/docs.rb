Lumen::App.controllers do
    
  get '/groups/:slug/docs' do
    redirect '/docs'
  end    
  
  get '/docs' do
    sign_in_required!
    @docs = current_account.docs    
    @docs = @docs.where(group_id: params[:group_id]) if params[:group_id]
    @docs = @docs.order_by(:created_at.desc)
    if request.xhr?
      partial :'docs/docs'
    else
      erb :'docs/docs'
    end
  end
  
  get '/docs/new' do
    sign_in_required!
    @title = 'Add a doc'
    partial :'groups/pick', :locals => {:collection => 'docs'}, :layout => (:modal if request.xhr?)
  end
  
  get '/groups/:slug/docs/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @doc = @group.docs.build
    erb :'docs/build'
  end  
        
  post '/groups/:slug/docs/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @doc = @group.docs.build(params[:doc])    
    @doc.account = current_account
    if @doc.save
      flash[:notice] = "<strong>Great!</strong> The doc was added successfully."
      redirect "/groups/#{@group.slug}/docs"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the doc from being saved."
      erb :'docs/build'      
    end
  end
  
  get  '/docs/:id/destroy' do    
    @doc = Doc.find(params[:id])
    membership_required!(@doc.group)
    @doc.destroy    
    flash[:notice] = 'The doc was removed.'
    redirect back
  end    
    
end