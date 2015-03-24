Lumen::App.controllers do
  
  get '/update_news' do
    site_admins_only!
    NewsSummary.each { |news_summary| news_summary.get_current_digest! }
    halt 200
  end  

  get '/news' do
    sign_in_required!
    if request.xhr?
      partial :'news/summaries', :locals => {:news_summaries => current_account.news_summaries, :date => (Time.now.hour >= 7 ? Date.today - 1 : Date.today - 2) + params[:d].to_i}
    else
      redirect "/#news-tab"
    end        
  end  
  
  get '/groups/:slug/news' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    if request.xhr?
      partial :'news/summaries', :locals => {:news_summaries => @group.news_summaries, :date => @group.news_date + params[:d].to_i}
    else
      redirect "/groups/#{@group.slug}#news-tab"
    end
  end  
    
  get '/groups/:slug/news_summaries' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    erb :'group_administration/news_summaries'    
  end  
  
  post '/groups/:slug/news_summaries/add' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @group.news_summaries.create :title => params[:title], :newsme_username => params[:newsme_username]
    redirect back
  end    
  
  get '/groups/:slug/news_summaries/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    @group.news_summaries.find(params[:id]).destroy
    redirect back
  end     
  
  get '/groups/:slug/news_summaries/:id/move_up' do
    @group = Group.find_by(slug: params[:slug])
    group_admins_only!
    news_summary = @group.news_summaries.find(params[:id])
    news_summaries = @group.news_summaries.order_by(:order.asc).to_a
    index = news_summaries.index(news_summary)
    if index > 0
      news_summaries[index-1], news_summaries[index] = news_summaries[index], news_summaries[index-1]
    end
    news_summaries.each_with_index { |x,i| x.update_attribute(:order, i) }
    redirect back
  end    
  
end