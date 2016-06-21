Lumen::App.controllers do
  
  before do
    @environment_variables = {
      :APP_NAME => 'App name (lowercase, no spaces) - Heroku app name if using Heroku',
      :GROUP_USERNAME_SUFFIX => 'Custom username suffix for groups (defaults to APP_NAME)',      
      
      :DOMAIN => 'Domain of Lumen web app',
      :MAIL_DOMAIN => 'Domain from which mails will be sent and received',

      :MAIL_SERVER_ADDRESS => 'Mail server address (no http://)',
      :MAIL_SERVER_USERNAME => 'Mail server username',
      :MAIL_SERVER_PASSWORD => 'Mail server password',
      
      :S3_BUCKET_NAME => 'S3 bucket name',
      :S3_ACCESS_KEY => 'S3 access key',
      :S3_SECRET => 'S3 secret',  
      :S3_REGION => 'S3 region',  
      
      :AIRBRAKE_HOST => 'Airbrake host (no http://)',
      :AIRBRAKE_API_KEY => 'Airbrake API key',      

      :SITE_NAME => 'Name of site e.g. Lumen Users Network',
      :SITE_NAME_DEFINITE => "Name of site with 'the' if appropriate e.g. The Lumen Users Network",
      :SITE_NAME_SHORT => 'Short site name e.g. LUN',
      :NAVBAR_BRAND => 'Content to appear in a.navbar-brand in the header',
      :HELP_ADDRESS => 'Email address for general queries',
      
      :DEFAULT_TIME_ZONE => 'Default time zone (see dropdown in profile for options, defaults to London)',
      :SANITIZE => ['Sanitize user input'],
  
      :REQUEST_LOCATION => ['Request location on request membership and join group forms'],      
      :REQUIRE_ACCOUNT_POSTCODE => ['Requires the completion of the postcode field on account profiles'],
      :REQUIRE_ACCOUNT_AFFILIATIONS => ['Requires some affiliations on account profiles'],
      :PREVENT_EMAIL_CHANGES => ['Prevents people from changing their email address'],
      :GROUP_CREATION_BY_ADMINS_ONLY => ['Only allow admins to create new groups'],
      :PRIVATE_NETWORK => ['Disables public membership requests and the Public group privacy option'],
      :LIST_EMAIL_ADDRESSES => ['Enables the \'List email addresses\' link in groups, allowing group members to copy a full list of emails'],
      
      :HIDE_SEARCH_MEMBERSHIPS => ['Hides group memberships on profile search results'],
      :HIDE_SEARCH_TAGS => ['Hides tags on profile search results'],      
            
      :AFFILIATION_POSITIONS => 'Comma-separated list of acceptable positions e.g. Novice,Intermediate,Master',
      :ACCOUNT_TAGS_PREDEFINED => ['Turns the tagships profile field into a series of checkboxes'],      
      :HIDE_ACCOUNT_HEADLINE => ['Hides headline on account profiles'],
      :HIDE_ACCOUNT_AFFILIATIONS => ['Hides affiliations on account profiles'],
      :HIDE_ACCOUNT_WEBSITE => ['Hides the website field on account profiles'],
      :HIDE_ACCOUNT_PHONE => ['Hides the phone field on account profiles'],
      :HIDE_ACCOUNT_TIME_ZONE => ['Hides the time zone field on account profiles'],
      :HIDE_ACCOUNT_EMAIL => ['Hides email addresses from account profiles and email notifications'],      
      :MAX_HEADLINE_LENGTH => 'Maximum character length  for the headline field (defaults to 150)',
      :ENV_FIELDS_ACCOUNT => 'Extra fields for the Account model e.g. biography:wysiwyg,research_proposal:file',
      
      :MAP_DEFAULTS => 'Comma-separated latitude, longitude and zoom',            
      :HIDE_PEOPLE_BY_DEFAULT => ['Hides people on maps by default'],
      :SHOW_EVENTS_BY_DEFAULT => ['Shows events on maps by default'],
      :SHOW_VENUES_BY_DEFAULT => ['Shows venues on maps by default'],
      :SHOW_ORGS_BY_DEFAULT => ['Shows organisations on maps by default'],
  
      :WALL_STYLE_CONVERSATIONS => ['Wall-style conversations'],
      :REPLY_TO_GROUP => ['Sets the reply-to header to the group address'],
      :HIGHLIGHTED_EVENT_LABEL_TEXT => 'Custom label text for highlighted events',
      
      :GROUP_INDEX_CONVERSATION_LIMIT => 'Shows this many conversations per group on /groups',
      
      :SHOW_COMPACT_ORG_FILTER => ['Shows the organisation filter on the compact account search form'],
      :SHOW_COMPACT_TAG_FILTER => ['Shows the account tag filter on the compact account search form'],
      :HIDE_COMPACT_SORT => ['Hides the sort field on the compact account search form'],
                    
      :FACEBOOK_KEY => 'Facebook API key',
      :FACEBOOK_SECRET => 'Facebook API secret',
      :GOOGLE_KEY => 'Google API key',
      :GOOGLE_SECRET => 'Google API secret',
      
      :GOOGLE_ANALYTICS_TRACKING_ID => 'Google Analytics tracking ID',
            
      :BCC_SINGLE => ['Send single BCC to conversation post subscribers'],
      :BCC_SINGLE_JOB => ['Handle single BCCs in the background'],      
      :BCC_EACH_THREADS => 'Number of threads to use when sending individual BCCs (default 10)',
      :POOL_TIMEOUT => 'Mongo production environment pool timeout in seconds. More threads may require a higher timeout. Default 30s.',      
      :INCLUDE_SENDER_PROFILE => ['Include sender profile in conversation post emails'],
      
      :SSL => ['Site served via SSL'],
      :VIRTUALMIN => ['Create mail accounts via Virtualmin (legacy option)'],      
      :HEROKU_OAUTH_TOKEN => 'Heroku OAuth token',
      :HEROKU_WORKOFF => ['Start a dyno to work off jobs on Heroku immediately after queueing (bypasses need for ongoing worker process)'],            
                  
      :PRIMARY_COLOR => 'Default #F5D74B',
      :PRIMARY_CONTRAST_COLOR => 'Default #222222',
      :PRIMARY_DARK_COLOR => 'Default #CDA70D',
      :SECONDARY_COLOR => 'Default #E74C3C',
      :SECONDARY_DARK_COLOR => 'Default #CD4435',
      :SECONDARY_LIGHT_COLOR => 'Default #F9DFDD',
      :GREY_LIGHT_COLOR => 'Default #ECF0F1',
      :GREY_MID_COLOR => 'Default #D6DBDF',
      :DARK_CONTRAST_COLOR => 'Default #F5D74B'    
    } 
    
    @fragments = {
      :'sign-in' => 'Text displayed on sign in page',
      :'first-time' => 'Text displayed on account edit page upon first login',
      :'home-above' => 'Content displayed above the buttons on the logged-in homepage',
      :'home-below' => 'Content displayed below the content columns on the logged-in homepage',
      :'public-homepage' => 'If defined, creates a public homepage with this HTML',
      :'groups' => 'Content to display on /groups',
      :'head' => 'Extra content for &lt;head&gt;',
      :'navbar' => 'Extra content for the navbar',
      :'right-col' => 'Right hand sidebar for fragment pages',
      :'footer' => 'Extra content for footer',
      :'nearby-group' => 'Content to display if user has a nearby group',
      :'tip-name' => 'Tip for the name field on account edit page',
      :'tip-affiliations' => 'Tip for affiliations field on account edit page',
      :'tip-tagships' => 'Tip for the areas of expertise field on account edit page',
      :'tip-email' => 'Tip for the email field on account edit page',
      :'below-account-email' => 'Text displayed below the email field on the account edit page',      
      :'tip-full-name' => 'Tip for the full name field on account edit page',
      :'tip-headline' => 'Tip for the headline field on account edit page',
      :'tip-town' => 'Tip for the town field on account edit page',
      :'tip-postcode' => 'Tip for the postcode field on account edit page',
      :'tip-country' => 'Tip for the country field on account edit page',
      :'tip-phone' => 'Tip for the phone field on account edit page',
      :'tip-website' => 'Tip for the website field on account edit page',
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
  curl -L --insecure http://$domain/groups/$1/check/?token=$token
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