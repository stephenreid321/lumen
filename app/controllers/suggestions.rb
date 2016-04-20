Lumen::App.controllers do
  
  post '/suggestions/new' do
    sign_in_required!
    @suggestion = Suggestion.new(params[:suggestion])    
    @suggestion.account = current_account
    @suggestion.save!
    flash[:notice] = params[:notice]
    redirect params[:redirect]
  end
 
end