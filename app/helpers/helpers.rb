ActivateApp::App.helpers do
  
  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
  end
  
  def protected!
    unless current_account
      flash[:notice] = 'You must sign in to access that page'
      session[:return_to] = request.url
      redirect '/sign_in' 
    end
  end
  
  def admins_only!
    unless current_account and current_account.role == 'admin'
      flash[:notice] = 'That page is protected'
      redirect '/' 
    end    
  end
  
  def generate_password(len)
    chars = ("a".."z").to_a + ("0".."9").to_a
    return Array.new(len) { chars[rand(chars.size)] }.join
  end     
  
end