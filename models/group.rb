class Group
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String
  field :analytics_conversation_threshold, :type => Integer, :default => ENV['SITEWIDE_ANALYTICS_CONVERSATION_THRESHOLD']
  
  def imap_address; "#{self.slug}@#{ENV['MAIL_DOMAIN']}"; end
  def smtp_address; "#{self.slug}-noreply@#{ENV['MAIL_DOMAIN']}"; end  
  
  field :imap_server, :type => String, :default => ENV['DEFAULT_IMAP_SERVER']
  field :imap_username, :type => String, :default => ->{ self.imap_address }
  field :imap_password, :type => String, :default => ENV['DEFAULT_IMAP_PASSWORD']    
  
  field :smtp_server, :type => String, :default => ENV['DEFAULT_SMTP_SERVER']
  field :smtp_port, :type => Integer, :default => 25
  field :smtp_authentication, :type => String, :default => 'login'
  field :smtp_ssl, :type => Boolean, :default => false
  field :smtp_username, :type => String, :default => ->{ self.smtp_address }
  field :smtp_password, :type => String, :default => ENV['DEFAULT_SMTP_PASSWORD']
  field :smtp_name, :type => String, :default => ->{ self.smtp_address }  
  field :smtp_sig, :type => String, :default => ->{ self.smtp_address }
  
  has_many :conversations, :dependent => :destroy
  has_many :conversation_posts, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :news_summaries, :dependent => :destroy
  has_many :didyouknows, :dependent => :destroy
  
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
    [:slug]
  end
  
  def self.fields_for_form
    {
      :slug => :text,
      :conversations => :collection
    }
  end
  
  def self.lookup
    :slug
  end
  
  def members
    Account.where(:id.in => memberships.only(:account_id).map(&:account_id))
  end
  
  after_create :setup_mail_accounts_and_forwarder
  def setup_mail_accounts_and_forwarder
    if ENV['CPANEL_URL']
      agent = Mechanize.new
      index = agent.post("#{ENV['CPANEL_URL']}/login", :user => ENV['CPANEL_USERNAME'], :pass => ENV['CPANEL_PASSWORD'])
      session_path = index.uri.to_s.split('index.html').first
      agent.post(session_path + "mail/doaddpop.html", :domain => ENV['MAIL_DOMAIN'], :email => self.slug, :password => self.imap_password, :password2 => self.imap_password, :quota => 0)
      agent.post(session_path + "mail/doaddpop.html", :domain => ENV['MAIL_DOMAIN'], :email => "#{self.slug}-noreply", :password => self.imap_password, :password2 => self.imap_password, :quota => 0)
      agent.post(session_path + "mail/doaddfwd.html", :domain => ENV['MAIL_DOMAIN'], :email => self.slug, :fwdopt => 'pipe', :fwdsystem => ENV['CPANEL_USERNAME'], :pipefwd => "#{ENV['CPANEL_NOTIFICATION_SCRIPT']} #{slug}")
    end
  end  
       
  def check!
    group = self
    logger.info "Attempting to log in as #{group.imap_username}"
    imap = Net::IMAP.new(group.imap_server, :ssl => true)
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
            html = Premailer.new(html, :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
              
            if html.include?('Respond by replying above this line')                
              if slugs = html.match(/http:\/\/.+\/conversations\/(\w+)/)
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
                html = "(there was an error processing the HTML of this email. Try pasting it in the box below.)"
                html_fuckup = true
              end
                
              conversation_post = conversation.conversation_posts.create! :body => html, :account => account, :mid => message_id     
              
              mail.attachments.each do |attachment|
                conversation_post.attachments.create! :file => attachment.body.decoded, :file_name => attachment.filename, :cid => attachment.cid
              end          
              
              if !html_fuckup
                conversation_post.send_notifications!((mail.to||[]) + (mail.cc||[]))
              end

            end
          end
        else
    
          Mail.defaults do
            delivery_method :smtp, { :address => group.smtp_server, :port => group.smtp_port, :authentication => group.smtp_authentication, :enable_ssl => group.smtp_ssl, :user_name => group.smtp_username, :password => group.smtp_password }
          end 
          mail = Mail.new(
            :to => from,
            :bcc => ENV['HELP_ADDRESS'],
            :from => "#{group.smtp_name} <#{group.smtp_address}>",
            :subject => "Delivery failed: #{envelope.subject}",
            :body => %Q{
Hi #{from},
   
You tried to send a message to the group '#{group.slug}', but you don't seem to be a member.

If you think you do belong to '#{group.slug}', check that the email address you're sending from matches the one registered to your account on #{ENV['DOMAIN']}.

Best,
#{group.smtp_sig}
            }
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
  
  def twitter_handles
    memberships.map(&:account).map(&:connections).flatten.select { |connection| connection.provider == 'Twitter' }.map { |connection| connection.omniauth_hash['info']['nickname'] }
  end
  
  def top_stories(from,to)
    x = []
    news_summaries.each { |news_summary|
      news_summary.daily_digests.each { |daily_digest|
        if daily_digest.date >= from and daily_digest.date < to+1
          Nokogiri::HTML(daily_digest.body).css('.story-content').each { |story|
            x << {:news_summary => news_summary, :daily_digest => daily_digest, :story => story}
          }
        end
      }
    }
    x.sort_by! { |e| e[:story].css('.story-tweeters a').length }    
    x.reverse!
    x
  end
  
end
