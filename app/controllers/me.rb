Lumen::App.controllers do
  
  get '/me' do
    sign_in_required!
    redirect "/accounts/#{current_account.id}"
  end
   
  get '/me/edit' do
    sign_in_required!
    @account = current_account
    if session[:validate]
      @account.valid?
      session[:validate] = nil
    end    
    erb :'accounts/build'
  end
  
  post '/me/edit' do
    sign_in_required!
    params[:account][:account_tag_ids] = [] if ENV['ACCOUNT_TAGS_PREDEFINED'] and !params[:account][:account_tag_ids]
    @account = current_account  
    @account.require_account_affiliations = ENV['REQUIRE_ACCOUNT_AFFILIATIONS'] 
    @account.prevent_email_changes = ENV['PREVENT_EMAIL_CHANGES'] 
    if @account.update_attributes(params[:account])      
      if params[:return]
        redirect back
      else
        flash[:notice] = "<strong>Great!</strong> Your account was updated successfully."
        if @account.sign_ins.count == 1 and @account.memberships.count > 0
          redirect (@account.memberships.first.group.try(:redirect_after_first_profile_save) || '/')
        else
          redirect '/me/edit'
        end
      end
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/build'
    end
  end
  
  get '/me/:provider/use_picture' do
    sign_in_required!
    @provider = Provider.object(params[:provider])
    @account = current_account
    @account.picture_url = @provider.image.call(@account.provider_links.find_by(provider: @provider.display_name).omniauth_hash)
    if @account.save
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Grabbed your picture!"
      redirect '/me/edit'
    else
      flash.now[:error] = "<strong>Hmm.</strong> There was a problem grabbing your picture."
      erb :'accounts/build'
    end
  end   
  
  get '/me/:provider/disconnect' do
    sign_in_required!
    @provider = Provider.object(params[:provider])    
    @account = current_account
    if @account.provider_links.find_by(provider: @provider.display_name).destroy
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Disconnected!"
      redirect '/me/edit'
    else
      flash.now[:error] = "<strong>Oops.</strong> The disconnect wasn't successful."
      erb :'accounts/build'
    end
  end  
    
  post '/me/destroy' do
    sign_in_required!
    if params[:name] and params[:name].downcase == current_account.name.downcase
      flash[:notice] = "Your account was deleted"
      current_account.destroy
      session.clear
      redirect '/sign_in'
    else
      flash[:notice] = "The name you typed didn't match the name on this account"
      redirect back
    end
  end
                      
end