Lumen::App.controllers do

  get '/digest' do
    sign_in_required!    
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
    @upcoming = @to + 7
    
    @top_stories = Hash[current_account.news_summaries.map { |news_summary| [news_summary, news_summary.top_stories(@from, @to)[0..2]] }]
    @accounts = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).select { |account| account.affiliated && account.picture }
    @conversations = current_account.conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.conversation_posts.count >= 3 }
    @new_events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @to).order_by(:start_time.asc)
    @period_events = current_account.events.where(:start_time.gte => @to).where(:start_time.lt => @upcoming+1).order_by(:start_time.asc)
    
    partial :'digest/digest', :locals => {:from => @from, :to => @to, :top_stories => @top_stories, :accounts => @accounts, :conversations => @conversations, :new_events => @new_events, :period_events => @period_events}, :layout => !request.xhr?
  end
  
  get '/groups/:slug/digest' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
    @upcoming = @to + 7
    
    @top_stories = Hash[@group.news_summaries.map { |news_summary| [news_summary, news_summary.top_stories(@from, @to)[0..2]] }]
    @accounts = @group.memberships.where(:created_at.gte => @from).where(:created_at.lt => @to+1).map(&:account).select { |account| account.affiliated && account.picture }
    @conversations = @group.conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.conversation_posts.count >= 3 }
    @new_events = @group.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @to).order_by(:start_time.asc)
    @period_events = @group.events.where(:start_time.gte => @to).where(:start_time.lt => @upcoming+1).order_by(:start_time.asc)
           
    if request.xhr?
      partial :'digest/digest', :locals => {:from => @from, :to => @to, :top_stories => @top_stories, :accounts => @accounts, :conversations => @conversations, :new_events => @new_events, :period_events => @period_events}
    else    
      if params[:email]
        @title = Nokogiri::HTML(params[:message].gsub('<br>',"\n")).text[0..149] if params[:message] # for Gmail snippet
        Premailer.new(partial(:'digest/digest', :layout => :email, :locals => {:from => @from, :to => @to, :top_stories => @top_stories, :accounts => @accounts, :conversations => @conversations, :new_events => @new_events, :period_events => @period_events}), :base_url => "http://#{ENV['DOMAIN']}", :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
      else
        erb :'groups/digest'
      end
    end
  end
  
end