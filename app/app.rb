module ActivateApp
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers  
    use Dragonfly::Middleware, :pictures
    use Dragonfly::Middleware, :files    
    
    set :sessions, :expire_after => 1.year
    # set :show_exceptions, true
    set :public_folder,  Padrino.root('app', 'assets')
        
    before do
      redirect "http://#{ENV['DOMAIN']}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = current_account.time_zone if current_account and current_account.time_zone    
      fix_params!    
      PageView.create(:account => current_account, :path => request.path) if current_account and !request.xhr?
    end     
      
    use OmniAuth::Builder do
      provider :account
      provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
      provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
      provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET']
      provider :linkedin, ENV['LINKEDIN_KEY'], ENV['LINKEDIN_SECRET']
    end  
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }
  
    if Padrino.env == :production
      use Rack::Cache, :metastore => Dalli::Client.new, :entitystore => 'file:tmp/cache/rack/body', :allow_reload => false
    end
               
    not_found do
      erb :not_found, :layout => :application
    end
  
    use Airbrake::Rack  
    Airbrake.configure do |config| config.api_key = ENV['AIRBRAKE_API_KEY'] end
    error do
      Airbrake.notify(env['sinatra.error'], :session => session) if Padrino.env == :production
      erb :error, :layout => :application
    end      
    get '/airbrake' do
      raise StandardError
    end
        
    ############
  
    get '/' do
      sign_in_required!
      @o = :updated
      @from = params[:from] ? params[:from].to_date : 1.week.ago.to_date
      @to = params[:to] ? params[:to].to_date : Date.today
    
      @top_stories = NewsSummary.top_stories(current_account.news_summaries, @from, @to)[0..4]
      @accounts = current_account.network.where(:created_at.gte => @from).where(:created_at.lt => @to+1).select { |account| account.affiliated && account.picture }
      @conversations = current_account.conversations.where(:updated_at.gte => @from).where(:updated_at.lt => @to+1).select { |conversation| conversation.conversation_posts.count >= 3 }
      @events = current_account.events.where(:created_at.gte => @from).where(:created_at.lt => @to+1)
        
      erb :home
    end
    
    get '/about' do
      sign_in_required!
      erb :about
    end    
    
    get '/update_news' do
      site_admins_only!
      NewsSummary.each { |news_summary| news_summary.get_current_digest! }
    end
        
    get '/analytics' do
      site_admins_only!      
      @conversation_threshold = ENV['SITEWIDE_ANALYTICS_CONVERSATION_THRESHOLD'].to_i     
      @models = [ConversationPost, Conversation, Account, Event, PageView].select { |model|
        model.count > 0
      }.select { |model|
        if model == Conversation
          Conversation.all.any? { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
        else
          true
        end
      }      
      @collections = @models.map { |model|
        resources = model.order_by(:created_at.asc) 
        if model == Conversation
          resources = resources.select { |conversation| conversation.conversation_posts.count >= @conversation_threshold }
        end
        resources
      }            
      erb :'groups/analytics'
    end
              
  end
end