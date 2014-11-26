Lumen::App.controllers do
  
  before do
    @environment_variables = {
      :APP_NAME => 'App name (lowercase, no spaces) - Heroku app name if using Heroku',
      :HEROKU_OAUTH_TOKEN => 'Heroku OAuth token',

      :DOMAIN => 'Domain of Lumen install',
      :MAIL_DOMAIN => 'Domain from which mails will be sent and received',

      :VIRTUALMIN_IP => 'IP for Virtualmin installation',
      :VIRTUALMIN_USERNAME => 'Username for Virtualmin',
      :VIRTUALMIN_PASSWORD => 'Password for Virtualmin',
      
      :S3_BUCKET_NAME => 'S3 bucket name',
      :S3_ACCESS_KEY => 'S3 access key',
      :S3_SECRET => 'S3 secret',  
      :S3_REGION => 'S3 region',  

      :SITE_NAME => 'Name of site e.g. Lumen Users Network',
      :SITE_NAME_DEFINITE => "Name of site with 'the' if appropriate e.g. The Lumen Users Network",
      :SITE_NAME_SHORT => 'Short site name e.g. LUN',
      :NOREPLY_NAME => "Name of email sender for general emails",
      :NOREPLY_SIG => "Email signature for general emails",
      :HELP_ADDRESS => 'Email address for general queries',

      :ENV_FIELDS_ACCOUNT => 'Extra fields for the Account model e.g. biography:wysiwyg,research_proposal:file',
  
      :AFFILIATION_POSITIONS => 'Comma-separated list of acceptable positions e.g. Novice,Intermediate,Master',
      :ACCOUNT_TAGS_PREDEFINED => ['Turns the tagships profile field into a series of checkboxes'],
      :REQUIRE_ACCOUNT_LOCATION => ['Requires the completion of the location field on account profiles'],
      :REQUIRE_ACCOUNT_AFFILIATIONS => ['Requires some affiliations on account profiles'],
      :GROUP_CREATION_BY_ADMINS_ONLY => ['Only allow admins to create new groups'],
          
      :HIDE_SEARCH_MEMBERSHIPS => ['Hides group memberships on profile search results'],
      :HIDE_SEARCH_TAGS => ['Hides tags on profile search results'],
      :HIDE_ORGANISATIONS_TAB => ['Hides the \'organisations\' tab'],
      :HIDE_SECTORS_TAB => ['Hides the \'sectors\' tab'],
      :HIDE_DIRECTORY_TAB => ['Hides the \'All groups\' tab'],
      :HIDE_MAP_FORM => ['Hides map form'],
      :HIDE_ACCOUNT_WEBSITE => ['Hides the website field on account profiles'],
      
      :HOME_TAB_ORDER => 'Custom tab order for homepage (comma-separated list from home, news, wall, digest, map, docs, surveys, calendar)',      
      :GROUP_TAB_ORDER => 'Custom tab order for groups (comma-separated list from home, conversations, news, wall, digest, map, docs, surveys, calendar)',
      
      :SHOW_PEOPLE_BY_DEFAULT => ['Shows people on maps by default'],
      :SHOW_SPACES_BY_DEFAULT => ['Shows spaces on maps by default'],
      :SHOW_ORGS_BY_DEFAULT => ['Shows organisations on maps by default'],
  
      :STACKED_HOME => ['Hides the homepage tabs and stacks the content instead'],
    
      :ICON_ORGANISATIONS => 'Alternative Font Awesome icon name for organisations tab',
      :ICON_SECTORS => 'Alternative Font Awesome icon name for sectors tab',
    
      :NEWSME_SWITCH_HOUR => "Hour to switch over to today's news summaries e.g. 11",  

      :FACEBOOK_KEY => 'Facebook API key',
      :FACEBOOK_SECRET => 'Facebook API secret',
      :LINKEDIN_KEY => 'LinkedIn API key',
      :LINKEDIN_SECRET => 'LinkedIn API secret',
      :GOOGLE_KEY => 'Google API key',
      :GOOGLE_SECRET => 'Google API secret',
      :TWITTER_KEY => 'Twitter API key',
      :TWITTER_SECRET => 'Twitter API secret',

      :AIRBRAKE_HOST => 'Airbrake host (no http://)',
      :AIRBRAKE_API_KEY => 'Airbrake API key',
      
      :MANDRILL_USERNAME => 'Mandrill username (experimental)',
      :MANDRILL_APIKEY => 'Mandrill API key/password (experimental)',
      
      :MAILGUN_USERNAME => 'Mailgun username (experimental)',
      :MAILGUN_APIKEY => 'Mailgun API key (experimental)',
      :MAILGUN_PASSWORD => 'Mailgun password (experimental)',
      
      :BCC_EACH => ['Send individual BCCs to conversation post subscribers (experimental)'],
      :BCC_EACH_THREADS => 'Number of threads to use to send individual BCCs (default 10)'
    } 
    
    @fragments = {
      :'about' => 'Text of about page',
      :'sign-in' => 'Text displayed on sign in page',
      :'first-time' => 'Text displayed on account edit page upon first login',
      :'public-homepage' => 'If defined, creates a public homepage with this HTML',
      :'head' => 'Extra content for &lt;head&gt;',
      :'navbar' => 'Extra content for the navbar',
      :'tip-affiliations' => 'Tip for affiliations field on account edit page',
      :'tip-location' => 'Tip for location field on account edit page'
    }     
  end
  
  get '/config' do
    site_admins_only!
    if ENV['APP_NAME'] and ENV['VIRTUALMIN_IP']
      Net::SSH.start(ENV['VIRTUALMIN_IP'], ENV['VIRTUALMIN_USERNAME'], :password => ENV['VIRTUALMIN_PASSWORD']) do |ssh|
        result = ''
        ssh.exec!("ls /notify") do |channel, stream, data|
          result << data
        end
        @notification_script = result.include?("#{ENV['APP_NAME']}.php")      
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
    require 'net/scp'
    Net::SSH.start(ENV['VIRTUALMIN_IP'], ENV['VIRTUALMIN_USERNAME'], :password => ENV['VIRTUALMIN_PASSWORD']) do  |ssh|
      ssh.exec!("mkdir /notify")
      ssh.exec!("chmod 777 /notify")
      Net::SCP.start(ENV['VIRTUALMIN_IP'], ENV['VIRTUALMIN_USERNAME'], :password => ENV['VIRTUALMIN_PASSWORD']) do |scp|
        scp.upload! StringIO.new(erb(:'notify/notify.php', :layout => false)), "/notify/#{ENV['APP_NAME']}.php"
        scp.upload! Padrino.root('app','views','notify','PlancakeEmailParser.php'), "/notify"
      end
      ssh.exec!("chmod 777 /notify/*")
    end
    redirect '/config'
  end  
      
end