class Group
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String
  field :analytics_conversation_threshold, :type => Integer, :default => ENV['SITEWIDE_ANALYTICS_CONVERSATION_THRESHOLD']
  
  def imap_address; "#{self.slug}@#{ENV['MAIL_DOMAIN']}"; end
  def smtp_address; "#{self.slug}-noreply@#{ENV['MAIL_DOMAIN']}"; end  
  
  field :imap_server, :type => String, :default => ENV['DEFAULT_IMAP_SERVER']
  field :imap_username, :type => String
  field :imap_password, :type => String, :default => ENV['DEFAULT_IMAP_PASSWORD']
  
  field :smtp_server, :type => String, :default => ENV['DEFAULT_SMTP_SERVER']
  field :smtp_username, :type => String
  field :smtp_password, :type => String, :default => ENV['DEFAULT_SMTP_PASSWORD']
  field :smtp_name, :type => String
  field :smtp_sig, :type => String
  
  def smtp_settings
    {:address => smtp_server, :user_name => smtp_username, :password => smtp_password, :port => 25, :authentication => 'login', :enable_starttls_auto => false}
  end
  
  has_many :conversations, :dependent => :destroy
  has_many :conversation_posts, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :news_summaries, :dependent => :destroy
  has_many :didyouknows, :dependent => :destroy
  has_many :markers, :dependent => :destroy
    
  def top_stories(from,to)
    Hash[news_summaries.order_by(:order.asc).map { |news_summary| [news_summary, news_summary.top_stories(from, to)[0..2]] }]
  end
  
  def new_people(from,to)
    memberships.where(:created_at.gte => from).where(:created_at.lt => to+1).map(&:account).select { |account| account.has_picture }
  end
  
  def hot_conversations(from,to)
    conversations.where(:hidden.ne => true).where(:updated_at.gte => from).where(:updated_at.lt => to+1).order_by(:updated_at.desc).select { |conversation| conversation.conversation_posts.where(:hidden.ne => true).count >= 3 }
  end
  
  def new_events(from,to)
    events.where(:created_at.gte => from).where(:created_at.lt => to+1).where(:start_time.gte => to).order_by(:start_time.asc)
  end
  
  def upcoming_events
    events.where(:start_time.gte => Date.today).where(:start_time.lt => Date.today+7).order_by(:start_time.asc)
  end  
  
  def members
    Account.where(:id.in => memberships.only(:account_id).map(&:account_id))
  end
  
  def twitter_handles
    memberships.map(&:account).map(&:connections).flatten.select { |connection| connection.provider == 'Twitter' }.map { |connection| connection.omniauth_hash['info']['nickname'] }
  end    
  
  validates_presence_of :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /[a-z0-9\-]+/
  
  def default_didyouknows
    [
      %Q{Every group has its own <a href="http://#{ENV['DOMAIN']}/groups/#{slug}/calendar">events calendar</a>, and #{slug} has [upcoming_events].},
      %Q{You can <a href="[conversation_url]">view this conversation on the web</a> to learn more about its participants.},
      %Q{You can <a href="http://#{ENV['DOMAIN']}/groups/#{slug}">search past conversations</a> of this group.},
      %Q{#{slug} has <a href="http://#{ENV['DOMAIN']}/groups/#{slug}">[members]</a>.},      
      %Q{The most recent profile update was made by <a href="[most_recently_updated_url]">[most_recently_updated_name]</a>.}
    ]
  end
       
  after_create :create_default_didyouknows
  def create_default_didyouknows
    default_didyouknows.each { |d| didyouknows.create :body => d }
  end
      
  def self.fields_for_index
    [:slug, :analytics_conversation_threshold]
  end
  
  def self.fields_for_form
    {
      :slug => :text,
      :analytics_conversation_threshold => :text,
      :imap_server => :text,
      :imap_username => :text,
      :imap_password => :text,   
      :smtp_server => :text,
      :smtp_username => :text,
      :smtp_password => :text,
      :smtp_name => :text,
      :smtp_sig => :text,
      :conversations => :collection
    }
  end
  
  def self.lookup
    :slug
  end
    
  after_create :setup_mail_accounts_and_forwarder
  def setup_mail_accounts_and_forwarder
    case ENV['MAILSERV_INTERFACE']
    when 'cpanel-11.4'
      agent = Mechanize.new
      index = agent.post("#{ENV['MAILSERV_URL']}/login", :user => ENV['MAILSERV_USERNAME'], :pass => ENV['MAILSERV_PASSWORD'])
      session_path = index.uri.to_s.split('index.html').first
      # Add inbound user
      agent.post(session_path + "mail/doaddpop.html", :domain => ENV['MAIL_DOMAIN'], :email => self.slug, :password => self.imap_password, :password2 => self.imap_password, :quota => 0)
      # Add outbound user
      agent.post(session_path + "mail/doaddpop.html", :domain => ENV['MAIL_DOMAIN'], :email => "#{self.slug}-noreply", :password => self.imap_password, :password2 => self.imap_password, :quota => 0)
      # Add pipe
      agent.post(session_path + "mail/doaddfwd.html", :domain => ENV['MAIL_DOMAIN'], :email => self.slug, :fwdopt => 'pipe', :fwdsystem => ENV['MAILSERV_USERNAME'], :pipefwd => "#{ENV['MAILSERV_NOTIFICATION_SCRIPT']} #{slug}")
    when 'virtualmin-4.04'
      agent = Mechanize.new
      agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      index = agent.get(ENV['MAILSERV_URL']).form_with(:action => '/session_login.cgi') do |f|
        f.user = ENV['MAILSERV_USERNAME']
        f.pass = ENV['MAILSERV_PASSWORD']
      end.submit
      form = index.frame_with(:src => 'left.cgi').click.form_with(:action =>'left.cgi')
      form.field_with(:name => 'dom').option_with(:value => /#{ENV['VIRTUALMIN_DOM']}/).click
      domain_page = form.submit
      users_page = domain_page.link_with(:text => 'Edit Users').click
      add_user_page = users_page.link_with(:text => 'Add a user to this server.').click
      aliases_page = domain_page.link_with(:text => 'Edit Mail Aliases').click
      add_alias_page = aliases_page.link_with(:text => 'Add an alias to this domain.').click.link_with(:text => 'Advanced mode').click
      # Add inbound user
      form = add_user_page.form_with(:action => 'save_user.cgi')
      form['mailuser'] = self.slug
      form['real'] = self.slug
      form['mailpass'] = self.imap_password
      form['quota'] = 0
      form.checkbox_with(:name => /forward/).check
      form['forwardto'] = "#{self.slug}-pipe@#{ENV['MAIL_DOMAIN']}"
      form.submit
      # Add outbound user
      form = add_user_page.form_with(:action => 'save_user.cgi')
      form['mailuser'] = "#{self.slug}-noreply"
      form['real'] = "#{self.slug}-noreply"
      form['mailpass'] = self.imap_password
      form['quota'] = 0
      form.submit
      # Add pipe
      form = add_alias_page.form_with(:action => 'save_alias.cgi')
      form['complexname'] = "#{self.slug}-pipe"
      form.field_with(:name => 'type_0').option_with(:text => /Feed to program/).click
      form['val_0'] = "#{ENV['MAILSERV_NOTIFICATION_SCRIPT']} #{slug}"
      form.submit        
    end
  end  
  
  def check!
    group = self
    logger.info "Attempting to log in as #{group.imap_username}"
    imap = Net::IMAP.new(group.imap_server)
    imap.authenticate('LOGIN', group.imap_username, group.imap_password)
    imap.select('INBOX')
    imap.search(["SINCE", Date.yesterday.strftime("%d-%b-%Y")]).each do |sequence_id|
                
      envelope = imap.fetch(sequence_id, "ENVELOPE")[0].attr["ENVELOPE"]        
      sender = "#{envelope.sender[0].mailbox}@#{envelope.sender[0].host}"
      from = "#{envelope.from[0].mailbox}@#{envelope.from[0].host}"
                                  
      # check this isn't a notification sent by the group         
      if sender != group.smtp_address
        # check the person that sent the message is a member of this group            
        if group.memberships.map { |membership| membership.account.email.downcase }.include? from.downcase
          # check this is a message we haven't seen before  
          message_id = imap.fetch(sequence_id,'UID')[0].attr['UID']
          if !group.conversation_posts.find_by(mid: message_id)
              
            msg = imap.fetch(sequence_id,'RFC822')[0].attr['RFC822']          
            mail = Mail.read_from_string msg
              
            account = Account.find_by(email: /^#{Regexp.escape(from)}$/i)
              
            if mail.html_part
              body = mail.html_part.body
              charset = mail.html_part.charset
              nl2br = false
            elsif mail.text_part                
              body = mail.text_part.body
              charset = mail.text_part.charset
              nl2br = true
            else
              body = mail.body
              charset = mail.charset
              nl2br = true
            end                            
              
            html = body.decoded.force_encoding(charset).encode('UTF-8')              
            html = html.gsub("\n", "<br>\n") if nl2br
            html = html.gsub(/<o:p>/, '')
            html = html.gsub(/<\/o:p>/, '')
            begin
              html = Premailer.new(html, :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
            rescue; end
              
              
            if html.include?('Respond by replying above this line')                
              if slugs = html.match(/http:\/\/#{ENV['DOMAIN']}\/conversations\/(\d+)/)
                conversation = group.conversations.find_by(slug: slugs[-1])
                html = html.split('Respond by replying above this line')[0]
                html = html.split(/On.+, .+ wrote:/)[0]
                html = html.split(/<span.*>From:<\/span>/)[0]      
                html = html.split('___________')[0]
                html = html.split(/<div.*#B5C4DF.*>/)[0]
              end
            else
              conversation = group.conversations.create! :subject => mail.subject
              html = html.split('DISCLAIMER: This e-mail is confidential')[0]
            end                
                                
            # if there's no conversation here, it means slugs[-1] was bad
            if conversation
                                
              html = Nokogiri::HTML.parse(html).search('body').inner_html
              if html.blank?
                html = "(there was an error processing the HTML of this email)"
                nokogiri_parse_fail = true
              end
                
              conversation_post = conversation.conversation_posts.create! :body => html, :account => account, :mid => message_id     
              
              mail.attachments.each do |attachment|
                conversation_post.attachments.create! :file => attachment.body.decoded, :file_name => attachment.filename, :cid => attachment.cid
              end          
              
              if !nokogiri_parse_fail
                conversation_post.send_notifications!(([mail.to].flatten + [mail.cc].flatten).compact.uniq)
              end

            end
          end
        else
    
          Mail.defaults do
            delivery_method :smtp, group.smtp_settings
          end 
          mail = Mail.new(
            :to => from,
            :bcc => ENV['HELP_ADDRESS'],
            :from => "#{group.smtp_name} <#{group.smtp_address}>",
            :subject => "Delivery failed: #{envelope.subject}",
            :body => ERB.new(File.read(Padrino.root('app/views/emails/delivery_failed.erb'))).result(binding)
          )
          mail.deliver! 
          imap.store(sequence_id, "+FLAGS", [:Deleted])
              
        end
      else
        imap.store(sequence_id, "+FLAGS", [:Deleted])
      end
      imap.store(sequence_id, "+FLAGS", [:Seen])
    end     
    imap.expunge
    imap.disconnect
  end
      
end
