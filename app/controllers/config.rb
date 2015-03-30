Lumen::App.controllers do
  
  before do
    @environment_variables = {
      :APP_NAME => 'App name (lowercase, no spaces) - Heroku app name if using Heroku',
      :HEROKU_OAUTH_TOKEN => 'Heroku OAuth token',

      :DOMAIN => 'Domain of Lumen install',
      :MAIL_DOMAIN => 'Domain from which mails will be sent and received',

      :MAIL_SERVER_ADDRESS => 'Mail server URL',
      :MAIL_SERVER_USERNAME => 'Mail server username',
      :MAIL_SERVER_PASSWORD => 'Mail server password',
      :GROUP_USERNAME_SUFFIX => 'Custom username suffix for groups',
      :VIRTUALMIN => ['Create mail accounts via Virtualmin'],
      
      :S3_BUCKET_NAME => 'S3 bucket name',
      :S3_ACCESS_KEY => 'S3 access key',
      :S3_SECRET => 'S3 secret',  
      :S3_REGION => 'S3 region',  
      
      :AIRBRAKE_HOST => 'Airbrake host (no http://)',
      :AIRBRAKE_API_KEY => 'Airbrake API key',      

      :SITE_NAME => 'Name of site e.g. Lumen Users Network',
      :SITE_NAME_DEFINITE => "Name of site with 'the' if appropriate e.g. The Lumen Users Network",
      :SITE_NAME_SHORT => 'Short site name e.g. LUN',
      :HELP_ADDRESS => 'Email address for general queries',
      :DEFAULT_TIME_ZONE => 'Default time zone (see dropdown in profile for options, defaults to London)',
      :SANITIZE => ['Sanitize user input'],
  
      :REQUIRE_ACCOUNT_LOCATION => ['Requires the completion of the location field on account profiles'],
      :REQUIRE_ACCOUNT_AFFILIATIONS => ['Requires some affiliations on account profiles'],
      :GROUP_CREATION_BY_ADMINS_ONLY => ['Only allow admins to create new groups'],
      :GROUPS_TO_JOIN_ON_FIRST_SIGN_IN => 'Comma-separated list of group slugs. People are automatically made members of these groups upon first sign-in',
          
      :HIDE_SEARCH_MEMBERSHIPS => ['Hides group memberships on profile search results'],
      :HIDE_SEARCH_TAGS => ['Hides tags on profile search results'],
      :HIDE_ORGANISATIONS_TAB => ['Hides the \'organisations\' tab'],
      :HIDE_SECTORS_TAB => ['Hides the \'sectors\' tab'],
      :HIDE_DIRECTORY_TAB => ['Hides the \'All groups\' tab'],
      :HIDE_GROUP_TYPE_TABS => ['Hides tabs for group types'],
      :HIDE_MAP_FORM => ['Hides map form'],
            
      :AFFILIATION_POSITIONS => 'Comma-separated list of acceptable positions e.g. Novice,Intermediate,Master',
      :ACCOUNT_TAGS_PREDEFINED => ['Turns the tagships profile field into a series of checkboxes'],      
      :HIDE_ACCOUNT_AFFILIATIONS => ['Hides affiliations on account profiles'],
      :SHOW_ACCOUNT_FULL_NAME => ['Shows the headline field on account profiles'],
      :SHOW_ACCOUNT_HEADLINE => ['Shows the headline field on account profiles'],
      :HIDE_ACCOUNT_WEBSITE => ['Hides the website field on account profiles'],
      :HIDE_ACCOUNT_PHONE => ['Hides the phone field on account profiles'],
      :HIDE_ACCOUNT_TIME_ZONE => ['Hides the time zone field on account profiles'],
      :HIDE_ACCOUNT_EMAIL => ['Hides email addresses from account profiles and email notifications'],      
      :ENV_FIELDS_ACCOUNT => 'Extra fields for the Account model e.g. biography:wysiwyg,research_proposal:file',
      
      :HOME_TAB_ORDER => 'Custom tab order for homepage (comma-separated list from global-landing, news, wall, digest, map, docs, surveys, calendar)',      
      :GROUP_TAB_ORDER => 'Custom tab order for groups (comma-separated list from global-landing, landing, conversations, news, wall, digest, map, docs, surveys, stats, calendar)',
      
      :SHOW_PEOPLE_BY_DEFAULT => ['Shows people on maps by default'],
      :SHOW_SPACES_BY_DEFAULT => ['Shows spaces on maps by default'],
      :SHOW_ORGS_BY_DEFAULT => ['Shows organisations on maps by default'],
  
      :STACKED_HOME => ['Hides the homepage tabs and stacks the content instead'],
    
      :ICON_ORGANISATIONS => 'Alternative Font Awesome icon name for organisations tab',
      :ICON_SECTORS => 'Alternative Font Awesome icon name for sectors tab',
          
      :FACEBOOK_KEY => 'Facebook API key',
      :FACEBOOK_SECRET => 'Facebook API secret',
      :LINKEDIN_KEY => 'LinkedIn API key',
      :LINKEDIN_SECRET => 'LinkedIn API secret',
      :GOOGLE_KEY => 'Google API key',
      :GOOGLE_SECRET => 'Google API secret',
      :TWITTER_KEY => 'Twitter API key',
      :TWITTER_SECRET => 'Twitter API secret',
      
      :GOOGLE_ANALYTICS_TRACKING_ID => 'Google Analytics tracking ID',
            
      :BCC_EACH => ['Send individual BCCs to conversation post subscribers (experimental)'],
      :BCC_EACH_THREADS => 'Number of threads to use to send individual BCCs (default 10)',
      :POOL_TIMEOUT => 'Mongo production environment pool timeout in seconds. More threads may require a higher timeout. Default 5s.',
      
    } 
    
    @fragments = {
      :'about' => 'Text of about page',
      :'sign-in' => 'Text displayed on sign in page',
      :'first-time' => 'Text displayed on account edit page upon first login',
      :'global-landing-tab' => 'Landing tab that can be displayed via HOME_TAB_ORDER and GROUP_TAB_ORDER',
      :'public-homepage' => 'If defined, creates a public homepage with this HTML',
      :'head' => 'Extra content for &lt;head&gt;',
      :'navbar' => 'Extra content for the navbar',
      :'tip-name' => 'Tip for the name field on account edit page',
      :'tip-affiliations' => 'Tip for affiliations field on account edit page',
      :'tip-tagships' => 'Tip for the areas of expertise field on account edit page',
      :'tip-email' => 'Tip for the email field on account edit page',
      :'below-account-email' => 'Text displayed below the email field on the account edit page',      
      :'tip-full-name' => 'Tip for the full name field on account edit page',
      :'tip-headline' => 'Tip for the headline field on account edit page',
      :'tip-location' => 'Tip for the location field on account edit page',
      :'tip-phone' => 'Tip for the phone field on account edit page',
      :'tip-website' => 'Tip for the location field on account edit page',
      :'tip-time-zone' => 'Tip for the time zone field on account edit page',
      :'tip-language' => 'Tip for the language field on account edit page',
    }     
  end
  
  get '/config' do
    site_admins_only!
    if ENV['APP_NAME'] and ENV['MAIL_SERVER_ADDRESS']
      Net::SSH.start(ENV['MAIL_SERVER_ADDRESS'], ENV['MAIL_SERVER_USERNAME'], :password => ENV['MAIL_SERVER_PASSWORD']) do |ssh|
        result = ''
        ssh.exec!("ls /notify") do |channel, stream, data|
          result << data
        end
        @notification_script = result.include?("#{ENV['APP_NAME']}.sh")      
      end
    end
    erb :config
  end
     
  post '/config' do
    site_admins_only!
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
    heroku.config_var.update(ENV['APP_NAME'], Hash[@environment_variables.map { |k,v| [k, params[k]] }])
    flash[:notice] = "Your config vars were updated. You may have to refresh the page for your changes to take effect."
    redirect '/config'
  end  
    
  get '/config/restart' do
    site_admins_only!
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
    heroku.dyno.restart_all(ENV['APP_NAME'])
    redirect back
  end
    
  get '/config/create_notification_script' do
    site_admins_only!    
    Net::SSH.start(ENV['MAIL_SERVER_ADDRESS'], ENV['MAIL_SERVER_USERNAME'], :password => ENV['MAIL_SERVER_PASSWORD']) do  |ssh|
      ssh.exec!("mkdir /notify")
      ssh.exec!("chmod 777 /notify")
      Net::SCP.start(ENV['MAIL_SERVER_ADDRESS'], ENV['MAIL_SERVER_USERNAME'], :password => ENV['MAIL_SERVER_PASSWORD']) do |scp|
        scp.upload! StringIO.new(%Q{#!/bin/bash
domain="#{ENV['DOMAIN']}"
maildomain="#{ENV['MAIL_DOMAIN']}"
token="#{Account.find_by(admin: true).secret_token}"
mailfile=`mktemp`
cat - > $mailfile

if ! grep -q "Sender: $1-noreply@$maildomain" $mailfile; then 
  curl http://$domain/groups/$1/check/?token=$token
fi

rm $mailfile}), "/notify/#{ENV['APP_NAME']}.sh"
      end
      ssh.exec!("chmod 777 /notify/#{ENV['APP_NAME']}.sh")
    end
    redirect '/config'
  end 
  
  get '/config/create_fragment/:slug' do
    redirect "/admin/edit/Fragment/#{Fragment.create(slug: params[:slug]).id}"
  end
      
end