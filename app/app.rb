module Lumen
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers  
    helpers Activate::NavigationHelpers
    
    use Dragonfly::Middleware
    use Airbrake::Rack    
    use OmniAuth::Builder do
      provider :account
      Provider.registered.each { |provider|
        provider provider.omniauth_name, ENV["#{provider.display_name.upcase}_KEY"], ENV["#{provider.display_name.upcase}_SECRET"], {provider_ignores_state: true}
      }
    end  
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }    
        
    set :sessions, :expire_after => 1.year
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'
        
    before do
      redirect "http://#{ENV['DOMAIN']}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = (current_account and current_account.time_zone) ? current_account.time_zone : 'London'
      I18n.locale = (current_account and current_account.language) ? current_account.language.code : Language.default.code
      fix_params!    
      PageView.create(:account => current_account, :path => request.path) if current_account and !request.xhr? and !params[:token]
    end     
     
    error do
      Airbrake.notify(env['sinatra.error'], :session => session)
      erb :error
    end 
               
    not_found do
      erb :not_found
    end
        
    ############
                  
    get '/' do
      if Account.count == 0       
        account = Account.create!(:name => 'Lumen Admin', :password => 'lumen', :password_confirmation => 'lumen', :email => 'admin@example.com', :admin => true)
        account.generate_secret_token
        SignIn.create(account: account)
        session['account_id'] = account.id
        flash[:notice] = %Q{<strong>Welcome to Lumen!</strong> An admin account has been created. You'll want to change the name, email address and password.}
        redirect '/me/edit'
      end      
      sign_in_required! unless Fragment.find_by(slug: 'public-homepage')
      if current_account
        if current_account.memberships.count == 1
          redirect "/groups/#{current_account.memberships.first.group.slug}"
        else
          @o = :updated       
          erb :home
        end
      else
        @containerless = true
        erb :'public/homepage'
      end
    end
    
    get '/global-landing' do
      sign_in_required!
      if request.xhr?
        Fragment.find_by(slug: 'global-landing-tab').try(:body)
      else
        redirect "/#{@group.slug}#global-landing-tab"
      end          
    end    
        
    get '/network' do
      sign_in_required!
      erb :network
    end    
            
    get '/about' do
      sign_in_required!
      erb :about
    end    
       
    get '/:slug' do      
      if @fragment = Fragment.find_by(slug: params[:slug], page: true)
        sign_in_required!
        erb :page
      else
        pass
      end
    end    
                          
  end
end