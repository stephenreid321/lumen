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
      Provider.all.each { |provider|
        if provider.registered?
          provider provider.omniauth_name, ENV["#{provider.display_name.upcase}_KEY"], ENV["#{provider.display_name.upcase}_SECRET"]
        end
      }
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
      if current_account.memberships.count == 1
        redirect "/groups/#{current_account.memberships.first.group.slug}"
      else
        @o = :updated       
        erb :home
      end
    end
    
    get '/home' do
      sign_in_required!
      @o = :updated       
      erb :home      
    end
    
    get '/config' do
      site_admins_only!
      erb :config
    end
        
    get '/about' do
      sign_in_required!
      erb :about
    end    
                          
  end
end