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
  
  post '/groups/:slug/surveys/:id' do
    @group = Group.find_by(slug: params[:slug])
    membership_required!
    @survey = @group.surveys.find(params[:id])
    @survey.survey_takers.find_by(account: current_account).try(:destroy)
    @survey_taker = @survey.survey_takers.build account: current_account
    params[:q].each { |k,v|      
      question = @survey.questions.find(k)
      case question.type
      when 'radio_buttons'
        if v == 'Other'
          v = params[:o][k]
        end
      when 'check_boxes'
        if v.include? 'Other'
          v[v.index('Other')] = params[:o][k]
        end
      end      
      if v
        @survey_taker.answers.build :question_id => k, :text => v.to_s
      end
    } if params[:q]
    if @survey_taker.save
      flash[:notice] = "Thanks for taking the survey."
      redirect (@survey.redirect_url || "/groups/#{@group.slug}/surveys")
    else
      flash.now[:error] = "Please correct the errors below and submit again"
      erb :'surveys/survey'
    end
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
        question_ids = @survey.questions.order('order asc').pluck(:id)
        csv << [nil,nil]+@survey.questions.order('order asc').pluck(:text)
        @survey.survey_takers.each do |survey_taker|
          account = survey_taker.account
          answers = {}
          survey_taker.answers.each { |answer| answers[answer.question_id] = answer.text }          
          csv << [account.name, survey_taker.created_at] + question_ids.map { |question_id| answers[question_id] }
        end
      end     
    end      
  end
    
end