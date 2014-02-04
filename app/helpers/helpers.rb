Lumen::App.helpers do
  
  def current_account
    @current_account ||= if session[:account_id]
      Account.find(session[:account_id])
    elsif params[:token]
      Account.find_by(secret_token: params[:token]) 
    end
  end
  
  def compact_daterange(from,to)
    if from.strftime("%b %Y") == to.strftime("%b %Y")
      from.day.ordinalize + " – " + to.strftime("#{to.day.ordinalize} %b %Y")
    else
      from.strftime("#{from.day.ordinalize} %b %Y") + " – " + to.strftime("#{to.day.ordinalize} %b %Y")
    end
  end
    
  def sign_in_required!
    unless current_account
      flash[:notice] = 'You must sign in to access that page' unless request.path == '/'
      session[:return_to] = request.url
      request.xhr? ? halt : redirect('/sign_in')
    end
  end
  
  def site_admins_only!
    unless current_account and current_account.admin?
      flash[:notice] = 'You must be a site admin to access that page'
      request.xhr? ? halt : redirect('/')
    end    
  end
  
  def membership_required!(group=nil)
    group = @group if !group
    unless current_account and group and group.memberships.find_by(account: current_account)
      flash[:notice] = 'You must be a member of that group to access that page'
      request.xhr? ? halt : redirect('/')
    end        
  end
  
  def group_admins_only!(group=nil)
    group = @group if !group
    unless current_account and group and (membership = group.memberships.find_by(account: current_account)) and membership.admin?
      flash[:notice] = 'You must be an admin of that group to access that page'
      request.xhr? ? halt : redirect('/')
    end     
  end
  
  def tt(string)
    if f = Fragment.find_by(slug: "tt-#{string.downcase.singularize}")
      s = f.body
      s = s.pluralize if string == string.pluralize
      s = s.capitalize if string == string.capitalize
      s
    else
      string
    end
  end
    
end
