Lumen::App.controllers do
  
  get '/groups/:slug/docs' do
    redirect '/docs'
  end    
  
  get '/docs' do
    sign_in_required!
    @docs = current_account.docs.order_by(:created_at.desc)
    erb :'docs/docs'
  end
        
  post '/groups/:slug/docs/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required!
    @doc = @group.docs.build(url: params[:url])    
    @doc.account = current_account
    if @doc.save
      redirect back
    else
      flash[:error] = "There was an error listing the doc. Make sure it's publicly viewable!"
      redirect back
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