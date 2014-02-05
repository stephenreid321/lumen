module Lumen
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers  

    use Dragonfly::Middleware, :pictures
    use Dragonfly::Middleware, :files    
    use Airbrake::Rack    
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
    
    set :sessions, :expire_after => 1.year
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'
        
    before do
      redirect "http://#{ENV['DOMAIN']}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = current_account.time_zone if current_account and current_account.time_zone    
      fix_params!    
      PageView.create(:account => current_account, :path => request.path) if current_account and !request.xhr?
    end     
     
    error do
      Airbrake.notify(env['sinatra.error'], :session => session)
      erb :error, :layout => :application
    end 
               
    not_found do
      erb :not_found, :layout => :application
    end
        
    ############
      
    get '/' do
      sign_in_required!
      @o = :updated        
      erb :home
    end
        
    get '/about' do
      sign_in_required!
      erb :about
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
      erb :'group_administration/analytics'
    end
              
  end
end