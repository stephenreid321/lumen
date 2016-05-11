Lumen::App.helpers do
  
  def current_account
    if session[:account_id]
      @current_account ||= Account.find(session[:account_id])
    end
  end
      
  def timeago(x)
    %Q{<abbr class="timeago" title="#{x.iso8601}">#{x}</abbr>}
  end
  
  def conversation_posts_badge(conversation)
    %Q{<span style="position: relative; top: -2px; opacity: #{(o = (0.3 + 0.7*((c = conversation.visible_conversation_posts.count).to_f/3))) > 1 ? 1 : o}" title="#{pluralize(c,'post')}" class="badge">#{c}</span>}
  end
  
  def g(group)
    unless group.primary
      %Q{<a title="#{I18n.t(:posted_in_the_group, name: group.name).capitalize}" class="group" href="/groups/#{group.slug}"><i class="fa fa-group"></i> #{group.name}</a>}
    end
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
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect('/sign_in')
    end
  end
  
  def site_admins_only!
    unless current_account and current_account.admin?
      flash[:notice] = 'You must be a site admin to access that page.'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect((current_account ? '/' : '/sign_in'))
    end    
  end
  
  def membership_required!(group=nil)
    group = @group if !group
    unless current_account and group and (group.memberships.find_by(account: current_account) or current_account.admin?)
      flash[:notice] = 'You must be a member of that group to access that page.'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(group.public? ? "/groups/#{group.slug}" : (current_account ? '/' : '/sign_in'))
    end        
  end
  
  def group_admins_only!(group=nil)
    group = @group if !group
    unless current_account and group and (((membership = group.memberships.find_by(account: current_account)) and membership.admin?) or current_account.admin?)
      flash[:notice] = 'You must be an admin of that group to access that page.'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(membership ? "/groups/#{group.slug}" : (current_account ? '/' : '/sign_in'))
    end     
  end
  
  def group_admins_and_creator_only!(group: nil, account: nil)
    group = @group if !group
    unless current_account and group and ((account == current_account) or (((membership = group.memberships.find_by(account: current_account)) and membership.admin?) or current_account.admin?))
      flash[:notice] = 'You must be an admin or creator to access that page.'
      session[:return_to] = request.url
      request.xhr? ? halt(403) : redirect(membership ? "/groups/#{group.slug}" : (current_account ? '/' : '/sign_in'))
    end          
  end    
  
  def random(relation, n)
    count = relation.count
    (0..count-1).sort_by{rand}.slice(0, n).collect! do |i| relation.skip(i).first end
  end
  
  def f(slug)
    (if fragment = Fragment.find_by(slug: slug) and fragment.body        
        "\"#{fragment.erb ? ERB.new(fragment.body).result(binding).gsub('"','\"') : fragment.body.gsub('"','\"')}\""
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
