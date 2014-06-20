Lumen::App.controllers do
  
  get '/docs' do
    sign_in_required!
    @docs = current_account.docs.order_by(:created_at.desc)
    if request.xhr?
      partial :'docs/docs'
    else
      redirect "/#docs-tab"
    end     
  end
    
  get '/groups/:slug/docs' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @docs = @group.docs.order_by(:created_at.desc)
    if request.xhr?
      partial :'docs/docs'
    else
      redirect "/groups/#{@group.slug}#docs-tab"
    end  
  end  
    
  post '/groups/:slug/docs/new' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @doc = @group.docs.build(url: params[:url])    
    @doc.account = current_account
    if @doc.save
      redirect "#{back}#docs-tab"
    else
      flash[:error] = 'There was an error listing the doc.'      
      redirect "#{back}#docs-tab"
    end
  end
  
  get  '/docs/:id/destroy' do    
    @doc = Doc.find(params[:id])
    membership_required!(@doc.group)
    @doc.destroy    
    flash[:notice] = 'The doc was removed.'
    redirect "#{back}#docs-tab"
  end    
    
end