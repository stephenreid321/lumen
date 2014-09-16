Lumen::App.controllers do
  
  get '/surveys' do
    sign_in_required!
    @surveys = current_account.surveys.order_by(:created_at.desc)
    if request.xhr?
      partial :'surveys/surveys'
    else
      redirect "/#surveys-tab"
    end      
  end
  
  get '/groups/:slug/surveys' do
    @group = Group.find_by(slug: params[:slug])
    membership_required! unless @group.open?
    @surveys = @group.surveys.order_by(:created_at.desc)
    if request.xhr?
      partial :'surveys/surveys'
    else
      redirect "/groups/#{@group.slug}#surveys-tab"
    end  
  end    
  
  get '/surveys/new' do
    sign_in_required!
    erb :'surveys/build' 
  end 
  
  get '/groups/:slug/surveys/new' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @survey = @group.surveys.build
    erb :'surveys/build'  
  end
  
  post '/groups/:slug/surveys/new' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @survey = @group.surveys.build(params[:survey])
    @survey.account = current_account
    if @survey.save
      flash[:notice] = 'The survey was created.'
      redirect "/groups/#{@group.slug}/surveys/#{@survey.id}"
    else
      flash[:error] = 'There were some errors creating the survey.'      
      erb :'surveys/build'
    end
  end
  
  get '/groups/:slug/surveys/:id/edit' do
    @group = Group.find_by(slug: params[:slug])
    @survey = @group.surveys.find(params[:id])    
    group_admins_and_creator_only!(account: @survey.account)
    erb :'surveys/build'  
  end
  
  post '/groups/:slug/surveys/:id/edit' do
    @group = Group.find_by(slug: params[:slug])
    @survey = @group.surveys.find(params[:id])    
    group_admins_and_creator_only!(account: @survey.account)
    if @survey.update_attributes(params[:survey])
      flash[:notice] = 'The survey was updated.'
      redirect "/groups/#{@group.slug}/surveys/#{@survey.id}"
    else
      flash[:error] = 'There were some errors saving the survey.'      
      erb :'surveys/build'
    end
  end
  
  get '/groups/:slug/surveys/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])
    @survey = @group.surveys.find(params[:id])    
    group_admins_and_creator_only!(account: @survey.account)
    @survey.destroy
    flash[:notice] = 'The survey was deleted.'
    redirect "/groups/#{@group.slug}/surveys"
  end
  
  get '/groups/:slug/surveys/:id' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @survey = @group.surveys.find(params[:id])
    erb :'surveys/survey'
  end    
  
  post '/groups/:slug/surveys/:id/answer' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @survey = @group.surveys.find(params[:id])
    @survey.answers.where(account: current_account).destroy_all
    params[:q].each { |k,v|
      @survey.questions.find(k).answers.create(:text => v, :account => current_account)
    }
    flash[:notice] = "Thanks for taking the survey."
    redirect "/groups/#{@group.slug}/surveys"
  end 
  
  get '/groups/:slug/surveys/:id/results', :provides => [:html, :csv] do
    @group = Group.find_by(slug: params[:slug])
    @survey = @group.surveys.find(params[:id])    
    group_admins_and_creator_only!(account: @survey.account)    
    case content_type
    when :html
      erb :'surveys/results'
    when :csv
      CSV.generate do |csv|
        csv << [nil,nil]+@survey.questions.map(&:text)
        @survey.takers.each do |account|
          csv << [account.name, @survey.answers.find_by(account: account).created_at] + @survey.questions.map { |question| question.answers.find_by(account: account).try(:text) }
        end
      end     
    end      
  end
    
end