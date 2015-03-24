Lumen::App.controllers do

  get '/digest' do
    sign_in_required!    
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
    
    @top_stories = Hash[current_account.news_summaries.order_by(:order.asc).map { |news_summary| [news_summary, news_summary.top_stories(@from, @to)[0..2]] }]
    @new_people = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:has_picture => true)
    @hot_conversations = current_account.visible_conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.visible_conversation_posts.count >= 3 }
    @new_events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @to).order_by(:start_time.asc)
    @upcoming_events = current_account.events.where(:start_time.gte => Date.today).where(:start_time.lt => Date.today+7).order_by(:start_time.asc)
    
    if request.xhr?      
      partial :'digest/digest', locals: {group: nil, message: nil, h2: nil, from: @from, to: @to, top_stories: @top_stories, new_people: @new_people, hot_conversations: @hot_conversations, new_events: @new_events, upcoming_events: @upcoming_events}
    else
      redirect "/#digest-tab"
    end
  end
  
  digest = lambda do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless (@group.open? or (current_account and current_account.admin?)) # via token
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today

    @top_stories = @group.top_stories(@from,@to)
    @new_people = @group.new_people(@from,@to)
    @hot_conversations = @group.hot_conversations(@from,@to)
    @new_events = @group.new_events(@from,@to)
    @upcoming_events = @group.upcoming_events
               
    if params[:for_email]
      @h2 = params[:h2]
      @message = params[:message]
      @title = Nokogiri::HTML(@message.gsub('<br>',"\n")).text[0..149] if @message # for Gmail snippet
      Premailer.new(
        partial(:'digest/digest', locals: {group: @group, message: @message, h2: @h2, from: @from, to: @to, top_stories: @top_stories, new_people: @new_people, hot_conversations: @hot_conversations, new_events: @new_events, upcoming_events: @upcoming_events}, :layout => :email),
        :base_url => "http://#{ENV['DOMAIN']}", :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
    elsif request.xhr?
      partial :'digest/digest', locals: {group: @group, message: nil, h2: nil, from: @from, to: @to, top_stories: @top_stories, new_people: @new_people, hot_conversations: @hot_conversations, new_events: @new_events, upcoming_events: @upcoming_events}
    else    
      redirect "/groups/#{@group.slug}#digest-tab"
    end  
  end  
  get  '/groups/:slug/digest', &digest
  post '/groups/:slug/digest', &digest
  
  get '/groups/:slug/review' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    erb :'group_administration/review'
  end  
  
  post '/groups/:slug/review' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today    
    @h2 = params[:h2]
    @customised_html = params[:customised_html]
    conversation = @group.conversations.create!(subject: "#{@h2}: #{compact_daterange(@from,@to)}", account: current_account)
    conversation_post = conversation.conversation_posts.create!(      
      :body => @customised_html,
      :account => current_account
    )
    conversation_post.send_notifications!
    flash[:notice] = "The review was sent."
    redirect "/groups/#{@group.slug}"
  end   
    
end