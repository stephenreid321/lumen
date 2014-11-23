Lumen::App.controllers do

  get '/digest' do
    sign_in_required!    
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today
    
    @top_stories = Hash[current_account.news_summaries.order_by(:order.asc).map { |news_summary| [news_summary, news_summary.top_stories(@from, @to)[0..2]] }]
    @new_people = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:has_picture => true)
    @hot_conversations = current_account.conversations.where(:hidden.ne => true).where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).order_by(:updated_at.desc).select { |conversation| conversation.conversation_posts.where(:hidden.ne => true).count >= 3 }
    @new_events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1).where(:start_time.gte => @to).order_by(:start_time.asc)
    @upcoming_events = current_account.events.where(:start_time.gte => Date.today).where(:start_time.lt => Date.today+7).order_by(:start_time.asc)
    
    if request.xhr?      
      partial :'digest/digest'
    else
      redirect "/#digest-tab"
    end
  end
  
  digest = lambda do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @from = params[:from] ? Date.parse(params[:from]) : 1.week.ago.to_date
    @to =  params[:to] ? Date.parse(params[:to]) : Date.today

    @top_stories = @group.top_stories(@from,@to)
    @new_people = @group.new_people(@from,@to)
    @hot_conversations = @group.hot_conversations(@from,@to)
    @new_events = @group.new_events(@from,@to)
    @upcoming_events = @group.upcoming_events
           
    if request.xhr?
      if params[:review]
        @review = true
        @h2 = params[:h2]
        @message = params[:message]
        @title = Nokogiri::HTML(@message.gsub('<br>',"\n")).text[0..149] if @message # for Gmail snippet
        Premailer.new(partial(:'digest/digest', :layout => :email), :base_url => "http://#{ENV['DOMAIN']}", :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
      else
        partial :'digest/digest'
      end
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
    conversation_post.queue_notifications!
    flash[:notice] = "The review was sent."
    redirect "/groups/#{@group.slug}"
  end   
  
  get '/send_digests/:notification_level' do
    site_admins_only!
    
    case params[:notification_level]
    when 'daily'
      @from = 1.day.ago.to_date
      @to = Date.today
    when 'weekly'      
      @from = 1.week.ago.to_date
      @to = Date.today
    end     
    
    Group.each { |group|  
      @group = group
      emails = group.memberships.where(notification_level: params[:notification_level]).map { |membership| membership.account.email }
      if emails.length > 0        

        @top_stories = @group.top_stories(@from,@to)
        @new_people = @group.new_people(@from,@to)
        @hot_conversations = @group.hot_conversations(@from,@to)
        @new_events = @group.new_events(@from,@to)
        @upcoming_events = @group.upcoming_events      
      
        if @top_stories.any? { |news_summary,stories| stories.length > 0 } or [@new_people, @hot_conversations, @new_events, @upcoming_events].any? { |x| x.length > 0 }
          @h2 = "Digest for #{group.slug}"
          html = Premailer.new(partial(:'digest/digest', :layout => :email), :base_url => "http://#{ENV['DOMAIN']}", :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
      
          Mail.defaults do
            delivery_method :smtp, group.smtp_settings
          end    
              
          mail = Mail.new
          mail.bcc = emails
          mail.from = "#{group.slug} <#{group.email('-noreply')}>"
          mail.subject = "#{@h2}: #{compact_daterange(@from,@to)}"
          mail.html_part do
            content_type 'text/html; charset=UTF-8'
            body html
          end
          mail.deliver                      
        end
      end             
    }
    halt 200
  end  
  
end