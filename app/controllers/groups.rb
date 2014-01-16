Lumen::App.controllers do
                        
  get '/groups/:slug' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!        
    @conversations = @group.conversations
    @q = params[:q] if params[:q]        
    if @q
      q = []
      ConversationPost.fields.each { |fieldstring, fieldobj|
        if fieldobj.type == String and !fieldstring.starts_with?('_')          
          q << {fieldstring.to_sym => /#{@q}/i }
        elsif fieldstring.ends_with?('_id') && (assoc_name = ConversationPost.fields[fieldstring].metadata.try(:class_name))          
          q << {"#{assoc_name.underscore}_id".to_sym.in => assoc_name.constantize.where(assoc_name.constantize.send(:lookup) => /#{@q}/i).only(:_id).map(&:_id) }
        end
      }   
      @conversation_posts = @group.conversation_posts.or(q)
      @conversations = @conversations.where(:id.in => @conversation_posts.only(:conversation_id).map(&:conversation_id))
    end                         
    @conversations = @conversations.per_page(10).page(params[:page])        
    erb :'groups/group'
  end  
  
  get '/groups/:slug/news' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!    
    partial :'news/summaries', :locals => {:news_summaries => @group.news_summaries, :date => NewsSummary.date + params[:d].to_i}
  end  
  
  get '/groups/:slug/review' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @from = 1.week.ago.to_date + 7*params[:w].to_i
    @to = Date.today + 7*params[:w].to_i
    
    @top_stories = Hash[@group.news_summaries.map { |news_summary| [news_summary, news_summary.top_stories(@from, @to)[0..2]] }]
    @accounts = @group.memberships.where(:created_at.gte => @from).where(:created_at.lt => @to+1).map(&:account).select { |account| account.affiliated && account.picture }
    @conversations = @group.conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.conversation_posts.count >= 3 }
    @new_events = @group.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @from).order_by(:start_time.asc)
    @period_events = @group.events.where(:start_time.gte => @from).where(:start_time.lt => @to+1).order_by(:start_time.asc)
           
    if request.xhr?
      partial :'review/review', :locals => {:from => @from, :to => @to, :top_stories => @top_stories, :accounts => @accounts, :conversations => @conversations, :new_events => @new_events, :period_events => @period_events}
    else    
      if params[:email]
        @title = Nokogiri::HTML(params[:message].gsub('<br>',"\n")).text[0..149] if params[:message] # for Gmail snippet
        Premailer.new(partial(:'review/review', :layout => :email, :locals => {:from => @from, :to => @to, :top_stories => @top_stories, :accounts => @accounts, :conversations => @conversations, :new_events => @new_events, :period_events => @period_events}), :base_url => "http://#{ENV['DOMAIN']}", :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
      else
        erb :'groups/review'
      end
    end
  end
  
  get '/groups/:slug/leave' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @group.memberships.find_by(:account => current_account).destroy
    redirect "/groups/#{@group.slug}"
  end  
  
  get '/groups/:slug/notification_level/:level' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @group.memberships.find_by(account: current_account).update_attribute(:notification_level, params[:level]) if Membership.notification_levels.include? params[:level]
    flash[:notice] = 'Notification options updated!'
    redirect "/groups/#{@group.slug}"
  end   
        
end