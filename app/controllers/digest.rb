Lumen::App.controllers do

  get '/digest' do
    sign_in_required!    
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
    
    @new_people = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:has_picture => true)
    @hot_conversations = current_account.visible_conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.visible_conversation_posts.count >= 3 }
    @new_events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @to).order_by(:start_time.asc)
    @upcoming_events = current_account.upcoming_events
    
    erb :'digest/digest'      
  end
  
  get '/groups/:slug/digest' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    membership_required! unless (@group.public? or (current_account and current_account.admin?)) # via token
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today

    @new_people = @group.new_people(@from,@to)
    @hot_conversations = @group.hot_conversations(@from,@to)
    @new_events = @group.new_events(@from,@to)
    @upcoming_events = @group.upcoming_events
               
    if params[:for_email]
      @h2 = params[:h2]
      @message = params[:message]
      @title = Nokogiri::HTML(@message.gsub('<br>',"\n")).text[0..149] if @message # for Gmail snippet
      Premailer.new(
        partial(:'digest/digest', locals: {group: @group, message: @message, h2: @h2, from: @from, to: @to, new_people: @new_people, hot_conversations: @hot_conversations, new_events: @new_events, upcoming_events: @upcoming_events}, :layout => :email),
        :base_url => "http://#{Config['DOMAIN']}", :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css      
    else    
      erb :'digest/digest'
    end  
  end  
       
end