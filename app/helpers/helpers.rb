Lumen::App.helpers do
  
  def current_account
    @current_account ||= if session[:account_id]
      Account.find(session[:account_id])
    elsif params[:token]
      Account.find_by(secret_token: params[:token]) 
    end
  end
  
  def smtp_settings
    {:address => ENV['VIRTUALMIN_IP'], :user_name => ENV['MAIL_DOMAIN'].split('.').first, :password => ENV['VIRTUALMIN_PASSWORD'], :port => 25, :authentication => 'login', :enable_starttls_auto => false}
  end
  
  def page_entries_info(collection, model: nil)
    if collection.total_pages < 2
      case collection.to_a.length
      when 0
        "No #{model.pluralize.downcase} found"
      when 1
        "Displaying <b>1</b> #{model.downcase}"
      else
        "Displaying <b>all #{collection.count}</b> #{model.pluralize.downcase}"
      end
    else
      "Displaying #{model.pluralize.downcase} <b>#{collection.offset + 1} - #{collection.offset + collection.to_a.length}</b> of <b>#{collection.count}</b> in total"
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
      flash[:notice] = 'You must sign in to access that page.'
      session[:return_to] ||= request.url
      request.xhr? ? halt(403) : redirect('/sign_in')
    end
  end
  
  def site_admins_only!
    unless current_account and current_account.admin?
      flash[:notice] = 'You must be a site admin to access that page.'
      session[:return_to] ||= request.url
      request.xhr? ? halt(403) : redirect('/')
    end    
  end
  
  def membership_required!(group=nil)
    group = @group if !group
    unless current_account and group and group.memberships.find_by(account: current_account)
      flash[:notice] = 'You must be a member of that group to access that page.'
      session[:return_to] ||= request.url
      request.xhr? ? halt(403) : redirect(group.open? ? "/groups/#{group.slug}" : '/')
    end        
  end
  
  def group_admins_only!(group=nil)
    group = @group if !group
    unless current_account and group and (membership = group.memberships.find_by(account: current_account)) and membership.admin?
      flash[:notice] = 'You must be an admin of that group to access that page.'
      session[:return_to] ||= request.url
      request.xhr? ? halt(403) : redirect(membership ? "/groups/#{group.slug}" : '/')
    end     
  end
  
  def group_admins_and_creator_only!(group: nil, account: nil)
    group = @group if !group
    unless (account == current_account) or (current_account and group and (membership = group.memberships.find_by(account: current_account)) and membership.admin?)
      flash[:notice] = 'You must be an admin or creator to access that page.'
      session[:return_to] ||= request.url
      request.xhr? ? halt(403) : redirect(membership ? "/groups/#{group.slug}" : '/')
    end          
  end    
  
  def random(relation, n)
    count = relation.count
    (0..count-1).sort_by{rand}.slice(0, n).collect! do |i| relation.skip(i).first end
  end
  
  def f(slug)
    (if fragment = Fragment.find_by(slug: slug) and fragment.body
        "\"#{fragment.body.to_s.gsub('"','\"')}\""
      end).to_s
  end 
  
  def refreshParent
    %q{
      <script>
      window.opener.location = window.opener.location;
      window.close();
      </script>
    }
  end  
      
end
