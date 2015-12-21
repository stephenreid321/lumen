Lumen::App.controllers do

  get '/digest' do
    sign_in_required!    
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
    
    @new_people = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:has_picture => true)
    @hot_conversations = current_account.visible_conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.visible_conversation_posts.count >= 3 }
    @new_events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @to).order_by(:start_time.asc)
    @upcoming_events = current_account.events.where(:start_time.gte => Date.today).where(:start_time.lt => Date.today+7).order_by(:start_time.asc)
    
    if request.xhr?      
      partial :'digest/digest', locals: {group: nil, message: nil, h2: nil, from: @from, to: @to, new_people: @new_people, hot_conversations: @hot_conversations, new_events: @new_events, upcoming_events: @upcoming_events}
    else
      redirect "/"
    end
  end
    
  get '/groups/:slug/review' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    group_admins_only!
    erb :'group_administration/review'
  end  
  
  post '/groups/:slug/review' do
    @group = Group.find_by(slug: params[:slug]) || not_found
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