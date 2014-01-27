Lumen::App.controllers do

  get '/news' do
    partial :'news/summaries', :locals => {:news_summaries => current_account.news_summaries, :date => NewsSummary.date + params[:d].to_i}
  end  
  
  get '/groups/:slug/news' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!    
    partial :'news/summaries', :locals => {:news_summaries => @group.news_summaries, :date => NewsSummary.date + params[:d].to_i}
  end  
  
end