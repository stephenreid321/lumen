Lumen::App.controllers do
  
  before do
    @environment_variables = {
      :APP_NAME => 'App name (lowercase, no spaces)',
      :GROUP_USERNAME_SUFFIX => 'Custom username suffix for groups (defaults to APP_NAME)',      
      
      :DOMAIN => 'Domain of Lumen web app',
      :MAIL_DOMAIN => 'Domain from which mails will be sent and received',
      
      :MAIL_SERVER_ADDRESS => 'Mail server address (no http://)',
      :MAIL_SERVER_USERNAME => 'Mail server username',
      :MAIL_SERVER_PASSWORD => 'Mail server password',
            
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
      
      :DMARC_FAIL_DOMAINS => 'Comma-separated list of domains with strict DMARC policies',
      
      :GOOGLE_ANALYTICS_TRACKING_ID => 'Google Analytics tracking ID',
      :GOOGLE_MAPS_API_KEY => 'Google Maps API key',
            
      :BCC_SINGLE => ['Send single BCC to conversation post subscribers'],
      :BCC_SINGLE_JOB => ['Handle single BCCs in the background'],      
      :BCC_EACH_THREADS => 'Number of threads to use when sending individual BCCs (default 10)',
      :INCLUDE_SENDER_PROFILE => ['Include sender profile in conversation post emails'],
      
      :SSL => ['Site served via SSL'],
      
      :SLACK_WEBHOOK_URL => 'Slack webhook URL',
      :SLACK_CHANNEL => 'Channel to post Slack notifications',
      
      :S3_BUCKET_NAME => 'S3 bucket name',
      :S3_ACCESS_KEY => 'S3 access key',
      :S3_SECRET => 'S3 secret',  
      :S3_REGION => 'S3 region',        
                  
      :PRIMARY_COLOR => 'Default #F5D74B',
      :PRIMARY_CONTRAST_COLOR => 'Default #222222',
      :SECONDARY_COLOR => 'Default #E74C3C',      
      :GREY_LIGHT_COLOR => 'Default #ECF0F1',
      :GREY_MID_COLOR => 'Default #D6DBDF',
      :DARK_COLOR => 'Default #333333',    
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
    if Config['APP_NAME'] and Config['MAIL_SERVER_ADDRESS']
      Net::SSH.start(Config['MAIL_SERVER_ADDRESS'], Config['MAIL_SERVER_USERNAME'], :password => Config['MAIL_SERVER_PASSWORD']) do |ssh|
        result = ''
        ssh.exec!("ls /notify") do |channel, stream, data|
          result << data
        end
        @notification_script = result.include?("#{Config['APP_NAME']}.sh")      
      end
    end
    erb :config
  end
     
  post '/config' do
    site_admins_only!
    @environment_variables.each { |k,v|
      config = Config.find_by(slug: k) || Config.create(slug: k)
      config.update_attribute(:body, params[k])
    }
    flash[:notice] = "Your config vars were updated. You may need to restart the server for your changes to take effect."
    redirect '/config'
  end  
    
  get '/config/restart' do
    site_admins_only!
    Delayed::Job.enqueue SshJob.new("dokku ps:rebuild #{Config['APP_NAME']}")
    flash[:notice] = "The app is restarting. Changes will take effect in a minute or two."
    redirect back
  end
    
  get '/config/create_notification_script' do
    site_admins_only!    
    Group.create_notification_script
    redirect '/config'
  end 
  
  get '/config/create_fragment/:slug' do
    redirect "/admin/edit/Fragment/#{Fragment.create(slug: params[:slug]).id}"
  end
      
end