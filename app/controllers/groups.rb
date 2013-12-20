ActivateApp::App.controllers do
                        
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
        elsif fieldstring.ends_with?('_id') && fieldstring != '_id' && Object.const_defined?((assoc_name = ConversationPost.fields[fieldstring].metadata.class_name))          
          q << {"#{assoc_name.underscore}_id".to_sym.in => assoc_name.constantize.where(assoc_name.constantize.send(:lookup) => /#{@q}/i).only(:_id).map(&:_id) }
        end          
      }   
      @conversation_posts = @group.conversation_posts.or(q)
      @conversations = @conversations.where(:id.in => @conversation_posts.only(:conversation_id).map(&:conversation_id))
    end                         
    @conversations = @conversations.per_page(10).page(params[:page])        
    erb :'groups/group'
  end  
  
  get '/groups/:slug/review' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @from = params[:from] ? params[:from].to_date : 1.week.ago.to_date
    @to = params[:to] ? params[:to].to_date : Date.today
    
    @top_stories = NewsSummary.top_stories(@group.news_summaries, @from, @to)[0..4]
    @accounts = @group.memberships.where(:created_at.gte => @from).where(:created_at.lt => @to+1).map(&:account).select { |account| account.affiliated && account.picture }
    @conversations = @group.conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).select { |conversation| conversation.conversation_posts.count >= 3 }
    @events = @group.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1)
        
    if request.xhr?
      partial :'review/review', :locals => {:from => @from, :to => @to, :top_stories => @top_stories, :accounts => @accounts, :conversations => @hot_conversations, :events => @events}
    else
      erb :'groups/review'
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