class Group    
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  field :name, :type => String  
  field :slug, :type => String
  field :primary, :type => Boolean
  field :allow_external_membership_requests, :type => Boolean
  field :description, :type => String
  field :privacy, :type => String
  field :default_notification_level, :type => String, :default => 'each'
  field :request_intro, :type => String  
  field :request_questions, :type => String
  field :landing_tab, :type => String
  field :redirect_after_first_profile_save, :type => String
  field :hot_conversation_threshold, :type => Integer, :default => 3
  field :show_full_conversations_in_digests, :type => Boolean
  field :picture_uid, :type => String 
  field :conversations_require_approval, :type => Boolean
  field :coordinates, :type => Array
  field :hide_from_dropdown, :type => Boolean
  field :conversation_creation_by_admins_only, :type => Boolean
  field :join_on_first_sign_in, :type => Boolean
        
  dragonfly_accessor :picture do
    after_assign { |picture| self.picture = picture.thumb('500x500>') }
  end  
    
  field :reminder_email_subject, :type => String, :default => -> { "A reminder to complete your profile on #{ENV['SITE_NAME_SHORT']}" }
  field :reminder_email, :type => String, :default => -> {
    %Q{Hi [firstname],
   <br /><br />
[admin] noticed that you haven't yet [issue] on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
Well-maintained profiles help build a stronger community. Will you spare a minute to provide the missing details?
<br /><br />
You can sign in at http://#{ENV['DOMAIN']}/sign_in.}
  }
    
  field :invite_email_subject, :type => String, :default => -> { "You were added to the group #{self.name} (#{self.email}) on #{ENV['SITE_NAME_SHORT']}" }
  field :invite_email, :type => String, :default => -> { 
    %Q{Hi [firstname],
<br /><br />
[admin] added you to the group #{self.name} (#{self.email}) on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
[sign_in_details]}
  }    
  
  field :membership_request_thanks_email_subject, :type => String, :default => -> { "Thanks for requesting membership of #{self.name} (#{self.email}) on #{ENV['SITE_NAME_SHORT']}" }
  field :membership_request_thanks_email, :type => String, :default => -> {
    %Q{Hi [firstname],
<br /><br />
Thanks for requesting membership of the group #{self.name} (#{self.email}) on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
The group administrators have been notified and will process your request shortly.}
  }
  
  field :membership_request_acceptance_email_subject, :type => String, :default => -> { "You're now a member of #{self.name} (#{self.email}) on #{ENV['SITE_NAME_SHORT']}" }
  field :membership_request_acceptance_email, :type => String, :default => -> {
    %Q{Hi [firstname],
<br /><br />
You have been granted membership of the group #{self.name} (#{self.email}) on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
[sign_in_details]}
  }
    
  index({slug: 1 }, {unique: true})
  
  validates_presence_of :name, :slug, :privacy
  validates_uniqueness_of :name, :slug
  validates_uniqueness_of :primary, :if => -> { self.primary }
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/  
  
  def email(suffix = '')
    "#{self.slug}#{suffix}@#{ENV['MAIL_DOMAIN']}"
  end
      
  def username(add = '')
    "#{slug}#{add}.#{ENV['GROUP_USERNAME_SUFFIX'] || ENV['APP_NAME']}"
  end
  
  def self.max_slug_length
    32 - "-noreply.#{ENV['GROUP_USERNAME_SUFFIX'] || ENV['APP_NAME']}".length
  end  
               
  def smtp_settings
    {:address => ENV['MAIL_SERVER_ADDRESS'], :user_name => self.username('-noreply'), :password => ENV['MAIL_SERVER_PASSWORD'], :port => 587, :enable_starttls_auto => true, :openssl_verify_mode => OpenSSL::SSL::VERIFY_NONE}
  end  
  
  has_many :conversations, :dependent => :destroy
  has_many :conversation_posts, :dependent => :destroy
  has_many :conversation_post_bccs, :dependent => :destroy
  has_many :conversation_post_read_receipts, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :didyouknows, :dependent => :destroy
  has_many :venues, :dependent => :destroy
  has_many :docs, :dependent => :destroy
  has_many :surveys, :dependent => :destroy
  
  def tags
    conversations.where(subject: /(?:\s|^)(?:#(?!(?:\d+|\w+?_|_\w+?)(?:\s|$)))(\w+)(?=\s|$)/i).map(&:tags).flatten.uniq.sort
  end
  
  def visible_conversations
    conversations.where(:hidden.ne => true)
  end
  
  def visible_conversation_posts
    conversation_posts.where(:hidden.ne => true)
  end
  
  belongs_to :group_type, index: true
        
  def new_people(from,to)
    Account.where(:id.in => memberships.where(:created_at.gte => from).where(:created_at.lt => to+1).pluck(:account_id)).where(:has_picture => true)
  end
  
  def approved_conversations
    conversations.where(:approved => true)
  end  
  
  def unapproved_conversations
    conversations.where(:hidden => true).where(:approved => nil)
  end
  
  def hot_conversations(from,to)
    visible_conversations.where(:updated_at.gte => from).where(:updated_at.lt => to+1).order_by(:updated_at.desc).select { |conversation| conversation.visible_conversation_posts.count >= hot_conversation_threshold }
  end
  
  def new_events(from,to)
    events.where(:created_at.gte => from).where(:created_at.lt => to+1).where(:start_time.gte => to).order_by(:start_time.asc)
  end
  
  def upcoming_events
    events.where(:start_time.gte => Date.today).where(:start_time.lt => Date.today+7).order_by(:start_time.asc)
  end  
  
  def members
    Account.where(:id.in => memberships.where(:status => 'confirmed').pluck(:account_id))
  end
  
  def people
    members
  end
  
  def admins
    Account.where(:id.in => memberships.where(:admin => true).pluck(:account_id))
  end
  
  def admins_receiving_membership_requests
    Account.where(:id.in => memberships.where(:admin => true, :receive_membership_requests => true).pluck(:account_id))
  end  
    
  def request_questions_a
    q = (request_questions || '').split("\n").map(&:strip) 
    q.empty? ? [] : q
  end

  def self.default_notification_levels
    {'On' => 'each', 'Off' => 'none', 'Daily digest' => 'daily', 'Weekly digest' => 'weekly'}
  end
    
  def default_didyouknows
    [
      %Q{You can <a href="[conversation_url]">view this conversation on the web</a> to learn more about its participants.},
      %Q{You can <a href="[site_url]/groups/[slug]">search past conversations</a> of this group.},
      %Q{#{slug} has <a href="[site_url]/groups/[slug]">[members]</a>.},      
      %Q{The most recent profile update was made by <a href="[most_recently_updated_url]">[most_recently_updated_name]</a>.}
    ]
  end
       
  after_create :create_default_didyouknows
  def create_default_didyouknows
    default_didyouknows.each { |d| didyouknows.create :body => d }
  end
      
  def self.admin_fields
    {
      :name => :text,
      :slug => :text,
      :primary => :check_box,
      :allow_external_membership_requests => :check_box,
      :description => :text_area,
      :picture => :image,
      :privacy => :radio,
      :conversations_require_approval => :check_box,
      :default_notification_level => :text,
      :request_intro => :text_area,      
      :request_questions => :text_area,
      :reminder_email => :text_area,
      :invite_email => :text_area,
      :membership_request_thanks_email => :text_area,
      :membership_request_acceptance_email => :text_area,
      :redirect_after_first_profile_save => :text,      
      :hot_conversation_threshold => :number,
      :show_full_conversations_in_digests => :check_box,
      :group_type_id => :lookup,
      :coordinates => :geopicker,      
      :hide_from_dropdown => :check_box,
      :conversation_creation_by_admins_only => :check_box,
      :join_on_first_sign_in => :check_box,
      :memberships => :collection,
      :membership_requests => :collection,
      :conversations => :collection
    }
  end
  
  def self.new_tips
    {
      :name => 'Full group name, all characters allowed',
      :redirect_after_first_profile_save => 'URL. Can be used to direct new members to a survey or conversation.',
      :request_intro => 'HTML to display above request form',
      :request_questions => 'Questions to ask to people requesting membership. One per line.',
      :invite_email => 'HTML. Replacements: [firstname], [admin], [sign_in_details]',
      :reminder_email => 'HTML. Replacements: [firstname], [admin], [issue]',
      :membership_request_thanks_email => 'HTML. Replacements: [firstname]',
      :membership_request_acceptance_email => 'HTML. Replacements: [firstname], [sign_in_details]'
    }
  end
  
  def self.edit_tips
    self.new_tips
  end
      
  def self.privacies
    p = {}
    (p['Public: group content is public and anyone can choose to join'] = 'public') unless ENV['PRIVATE_NETWORK']
    p['Open: anyone can choose to join'] = 'open'
    p['Closed: people must request membership'] = 'closed'
    p['Secret: group is hidden and people can only join via invitation'] = 'secret'      
    p
  end
  
  def public?
    privacy == 'public'
  end  
  
  def open?
    privacy == 'open'
  end
  
  def closed?
    privacy == 'closed'
  end
  
  def secret?
    privacy == 'secret'
  end
  
  def send_digests(notification_level)
    group = self        
    emails = group.memberships.where(notification_level: notification_level.to_s).map { |membership| membership.account.email }
    if emails.length > 0                        
      
      case notification_level
      when :daily
        from = 1.day.ago.to_date
        to = Date.today
      when :weekly      
        from = 1.week.ago.to_date
        to = Date.today
      end   
      
      h2 = "Digest for #{group.slug}"        
      # is there a better way of accessing the controller context?
      html = open("http://#{ENV['DOMAIN']}/groups/#{group.slug}/digest?from=#{from.to_s(:db)}&to=#{to.to_s(:db)}&for_email=true&h2=#{URI.escape(h2)}&token=#{Account.find_by(admin: true).secret_token}", :allow_redirections => :safe, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read
        
      if html.include?('Conversations') or html.include?('Hot conversations') or html.include?('New people') or html.include?('New events') or html.include?('Top stories')
        Mail.defaults do
          delivery_method :smtp, group.smtp_settings
        end    
      
        # can't access the compact_daterange helper, so...
        daterange = if from.strftime("%b %Y") == to.strftime("%b %Y")
          from.day.ordinalize + " – " + to.strftime("#{to.day.ordinalize} %b %Y")
        else
          from.strftime("#{from.day.ordinalize} %b %Y") + " – " + to.strftime("#{to.day.ordinalize} %b %Y")
        end
              
        mail = Mail.new
        mail.bcc = emails
        mail.from = "#{group.slug} <#{group.email('-noreply')}>"
        mail.subject = "#{h2}: #{daterange}"
        mail.html_part do
          content_type 'text/html; charset=UTF-8'
          body html
        end
        mail.deliver                      
      end

    end    
  end
      
  after_create :setup_mail_accounts_and_forwarder
  def setup_mail_accounts_and_forwarder
    if ENV['MAIL_SERVER_ADDRESS'] and !@setup_complete
      if ENV['VIRTUALMIN']
        Delayed::Job.enqueue SetupMailAccountsAndForwarderViaVirtualminJob.new(self.id)
      else      
        group = self
        Net::SSH.start(ENV['MAIL_SERVER_ADDRESS'], ENV['MAIL_SERVER_USERNAME'], :password => ENV['MAIL_SERVER_PASSWORD']) do  |ssh|
          ssh.exec!("useradd -d /home/#{group.username('-inbox')} -m #{group.username('-inbox')}; echo #{group.username('-inbox')}:#{ENV['MAIL_SERVER_PASSWORD']} | chpasswd")
          ssh.exec!("useradd -d /home/#{group.username('-noreply')} -m #{group.username('-noreply')}; echo #{group.username('-noreply')}:#{ENV['MAIL_SERVER_PASSWORD']} | chpasswd")                      
          ssh.exec!(%Q{echo '#{group.slug}@#{ENV['MAIL_DOMAIN']} #{group.username}' >> /etc/postfix/virtual})
          ssh.exec!(%Q{echo '#{group.username}: #{group.username('-inbox')}, "| /notify/#{ENV['APP_NAME']}.sh #{group.slug}"' >> /etc/aliases})
          ssh.exec!("newaliases")        
          ssh.exec!("postmap /etc/postfix/virtual")
          ssh.exec!("service postfix restart")
        end        
      end
      @setup_complete = true
    end    
  end
  
  after_destroy :remove_mail_accounts_and_forwarder
  def remove_mail_accounts_and_forwarder
    if ENV['MAIL_SERVER_ADDRESS'] and !ENV['VIRTUALMIN']
      group = self
      Net::SSH.start(ENV['MAIL_SERVER_ADDRESS'], ENV['MAIL_SERVER_USERNAME'], :password => ENV['MAIL_SERVER_PASSWORD']) do  |ssh|
        ssh.exec!("deluser #{group.username('-inbox')} --remove-home")
        ssh.exec!("deluser #{group.username('-noreply')} --remove-home")
        ssh.exec!(%Q{sed -i '/#{Regexp.escape(%Q{#{group.slug}@#{ENV['MAIL_DOMAIN']} #{group.username}}).gsub('/','\/')}/d' /etc/postfix/virtual})
        ssh.exec!(%Q{sed -i '/#{Regexp.escape(%Q{#{group.username}: #{group.username('-inbox')}, "| /notify/#{ENV['APP_NAME']}.sh #{group.slug}"}).gsub('/','\/')}/d' /etc/aliases})
        ssh.exec!("newaliases")        
        ssh.exec!("postmap /etc/postfix/virtual")
        ssh.exec!("service postfix restart")    
      end
    end
  end  
    
  def setup_mail_accounts_and_forwarder_via_virtualmin    
    group = self   
    agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    index = agent.get("https://#{ENV['MAIL_SERVER_ADDRESS']}:10000").form_with(:action => '/session_login.cgi') do |f|
      f.user = ENV['MAIL_SERVER_USERNAME']
      f.pass = ENV['MAIL_SERVER_PASSWORD']
    end.submit
    form = index.frames[0].click.forms[0]
    form.field_with(:name => 'dom').option_with(:text => /#{Regexp.escape(ENV['MAIL_DOMAIN'][0..9])}/).click
    domain_page = form.submit
    users_page = domain_page.link_with(:text => 'Edit Users').click
    add_user_page = users_page.link_with(:text => 'Add a user to this server.').click
    aliases_page = domain_page.link_with(:text => 'Edit Mail Aliases').click
    add_alias_page = aliases_page.link_with(:text => 'Add an alias to this domain.').click.link_with(:text => 'Advanced mode').click
    # Add inbound user
    form = add_user_page.form_with(:action => 'save_user.cgi')
    form['mailuser'] = "#{group.slug}-inbox"
    form['mailpass'] = ENV['MAIL_SERVER_PASSWORD']
    form['quota'] = 0
    form.submit
    # Add outbound user
    form = add_user_page.form_with(:action => 'save_user.cgi')
    form['mailuser'] = "#{group.slug}-noreply"
    form['mailpass'] = ENV['MAIL_SERVER_PASSWORD']
    form['quota'] = 0
    form.submit    
    # Add pipe
    form = add_alias_page.form_with(:action => 'save_alias.cgi')
    form['complexname'] = group.slug
    form.field_with(:name => 'type_0').option_with(:text => /Mailbox of user/).click
    form['val_0'] = group.username('-inbox')
    form.field_with(:name => 'type_1').option_with(:text => /Feed to program/).click
    form['val_1'] = "/notify/#{ENV['APP_NAME']}.sh #{group.slug}"
    form.submit
  end
      
  attr_accessor :renamed
  before_validation do
    errors.add(:slug, "is too long: max #{Group.max_slug_length} characters") if !ENV['VIRTUALMIN'] and self.slug and self.slug.length > Group.max_slug_length
    @renamed = slug_changed?
    true
  end
  after_save :rename
  def rename
    if persisted? and @renamed
      setup_mail_accounts_and_forwarder
      conversation_posts.update_all(imap_uid: nil)
    end
  end
  
  def send_welcome_emails
    memberships.where(:welcome_email_pending => true).each(&:send_welcome_email)
  end
    
  def check!(since: Date.yesterday)
    return unless ENV['MAIL_SERVER_ADDRESS']
    group = self
    imap = Net::IMAP.new(ENV['MAIL_SERVER_ADDRESS'], :ssl => { :verify_mode => OpenSSL::SSL::VERIFY_NONE })
    begin
      imap.authenticate('PLAIN', group.username('-inbox'), ENV['MAIL_SERVER_PASSWORD'])
    rescue # try former/deprecated account form
      imap.authenticate('PLAIN', group.username, ENV['MAIL_SERVER_PASSWORD'])
    end
    imap.select('INBOX')  
    
    # delete messages sent by lumen
    sent_by_lumen = imap.search(['HEADER', 'Sender', group.email('-noreply')])
    if !sent_by_lumen.empty?
      imap.store(sent_by_lumen, "+FLAGS", [:Deleted])
      imap.expunge
    end

    imap.search(["SINCE", since.strftime("%d-%b-%Y"), 'NOT', 'HEADER', 'Sender', group.email('-noreply')]).each do |sequence_id|
      
      # skip messages we've already dealt with
      imap_uid = imap.fetch(sequence_id,'UID')[0].attr['UID']
      puts "fetched message with uid #{imap_uid}"
      if group.conversation_posts.find_by(imap_uid: imap_uid)
        puts "already created a post with this message id, skipping"
        next
      end        
                                  
      mail = Mail.read_from_string(imap.fetch(sequence_id,'RFC822')[0].attr['RFC822'])
      
      case process_mail(mail, imap_uid: imap_uid)
      when :delete
        puts "deleting"
        imap.store(sequence_id, "+FLAGS", [:Deleted])
        next
      when :failed
        puts "failed, skipping"
        next
      end
                  
      imap.store(sequence_id, "+FLAGS", [:Seen])
    end 
    imap.expunge
    imap.disconnect
  end
  
  def process_mail(mail, imap_uid: nil)
    group = self
    return :failed unless mail.from
    from = mail.from.first
    
    puts "message from #{from}"
        
    # check this isn't a message sent by Lumen
    if mail.sender == group.email('-noreply')
      raise "a message sent by Lumen made it into #{group.slug}'s inbox"
    end 
                                   
    # skip messages from people that aren't in the group
    account = Account.find_by(email: /^#{Regexp.escape(from)}$/i)     
    if !account or !account.memberships.find_by(:group => group, :status => 'confirmed', :muted.ne => true)
      begin
        Mail.defaults do
          delivery_method :smtp, group.smtp_settings
        end 
        mail = Mail.new(
          :to => from,
          :bcc => ENV['HELP_ADDRESS'],
          :from => "#{group.slug} <#{group.email('-noreply')}>",
          :subject => "Delivery failed: #{mail.subject}",
          :body => ERB.new(File.read(Padrino.root('app/views/emails/delivery_failed.erb'))).result(binding)
        )
        mail.deliver
      rescue => e
        Airbrake.notify(e)
      end
        
      puts "this message was sent by a stranger"
      return :delete
    end    
    
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
              
    html = begin; body.decoded.force_encoding(charset).encode('UTF-8'); rescue; body; end
    html = html.gsub("\n", "<br>\n") if nl2br
    html = html.gsub(/<o:p>/, '')
    html = html.gsub(/<\/o:p>/, '')
    begin
      html = Premailer.new(html, :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
    rescue => e
      Airbrake.notify(e)
    end

    if (
        (mail.in_reply_to and (conversation = ConversationPostBcc.find_by(message_id: mail.in_reply_to).try(:conversation)) and conversation.group == group) or
          (
          html.match(/Respond\s+by\s+replying\s+above\s+this\s+line/) and
            (conversation_url_match = html.match(/http:\/\/#{ENV['DOMAIN']}\/conversations\/(\d+)/)) and
            conversation = group.conversations.find_by(slug: conversation_url_match[-1])
        )
      )
      new_conversation = false
      puts "part of conversation id #{conversation.id}"
      [/Respond\s+by\s+replying\s+above\s+this\s+line/, /On.+, .+ wrote:/, /<span.*>From:<\/span>/, '___________','<hr id="stopSpelling">'].each { |pattern|
        html = html.split(pattern).first
      }
    else      
      new_conversation = true
      conversation = group.conversations.create :subject => (mail.subject.blank? ? '(no subject)' : mail.subject), :account => account
      return :failed if !conversation.persisted? # failed to find/create a valid conversation - probably a dupe
      puts "created new conversation id #{conversation.id}"
    end
      
    html = Nokogiri::HTML.parse(html)
    html.search('style').remove
    # html.search('.gmail_extra').remove
    html = html.search('body').inner_html
                     
    conversation_post = conversation.conversation_posts.create :body => html, :account => account, :imap_uid => imap_uid, :message_id => mail.message_id
    if !conversation_post.persisted? # failed to create the conversation post
      puts "failed to create conversation post, deleting conversation"
      conversation.destroy if new_conversation
      return :failed
    end
    puts "created conversation post id #{conversation_post.id}"
    mail.attachments.each do |attachment|
      file = Tempfile.new(attachment.filename)
      begin
        file.binmode
        file.write(attachment.body)
        file.original_filename = attachment.filename
        conversation_post.attachments.create :file => file, :file_name => attachment.filename, :cid => attachment.cid
      ensure
        file.close
        file.unlink
      end      
    end         
    puts "sending notifications"
    conversation_post.send_notifications!
  end
  
  def test_creating_a_conversation_via_email
    group = self
    Mail.defaults do
      delivery_method :smtp, group.smtp_settings
    end    
    mail = Mail.new
    mail.to = group.email
    mail.from = group.members.first.email
    subject = "test #{Time.now.to_s(:db)}"
    mail.subject = subject
    mail.body = '.'
    puts "sending email with subject #{subject}"
    mail.deliver          
    puts "sleeping for 1 minute"
    sleep 60
    puts "checking for conversation with subject #{subject}"
    conversation = group.conversations.order(:created_at.desc).limit(1).first
    if conversation and conversation.subject == subject
      puts "conversation created"
    else
      begin
        raise (r = "failed to create conversation: #{subject}")
      rescue => e
        puts r
        Airbrake.notify(e)
      end
    end
    puts "checking for bccs"
    if conversation.conversation_posts.first.conversation_post_bccs.count > 0
      puts "bccs created"
    else
      begin
        raise (r = "failed to create bccs: #{subject}")
      rescue => e
        puts r
        Airbrake.notify(e)
      end
    end    
  end
      
end
