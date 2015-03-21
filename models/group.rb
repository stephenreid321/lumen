class Group
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String
  field :description, :type => String
  field :privacy, :type => String
  field :default_notification_level, :type => String, :default => 'each'
  field :request_intro, :type => String  
  field :request_questions, :type => String
  field :landing_tab, :type => String
  field :redirect_after_first_profile_save, :type => String
    
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
    
  field :invite_email_subject, :type => String, :default => -> { "You were added to the '#{self.slug}' group on #{ENV['SITE_NAME_SHORT']}" }
  field :invite_email, :type => String, :default => -> { 
    %Q{Hi [firstname],
<br /><br />
[admin] added you to the '#{self.slug}' group on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
[sign_in_details]}
  }    
  
  field :membership_request_thanks_email_subject, :type => String, :default => -> { "Thanks for requesting membership of '#{self.slug}' on #{ENV['SITE_NAME_SHORT']}" }
  field :membership_request_thanks_email, :type => String, :default => -> {
    %Q{Hi [firstname],
<br /><br />
Thanks for requesting membership of the '#{self.slug}' group on on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
The group administrators have been notified and will process your request shortly.}
  }
  
  field :membership_request_acceptance_email_subject, :type => String, :default => -> { "You're now a member of '#{self.slug}' on #{ENV['SITE_NAME_SHORT']}" }
  field :membership_request_acceptance_email, :type => String, :default => -> {
    %Q{Hi [firstname],
<br /><br />
You have been granted membership of the '#{self.slug}' group on #{ENV['SITE_NAME_DEFINITE']}.
<br /><br />
[sign_in_details]}
  }
    
  index({slug: 1 }, {unique: true})
  
  validates_presence_of :slug, :privacy
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/  
  
  def email(suffix = '')
    "#{self.slug}#{suffix}@#{ENV['MAIL_DOMAIN']}"
  end
      
  def username(add = '')
    u = "#{slug}"
    u << add
    u << (ENV['VIRTUALMIN_USERNAME_SUFFIX'] || ENV['MAIL_DOMAIN'].split('.').first)
    u
  end
               
  def smtp_settings
    {:address => ENV['VIRTUALMIN_IP'], :user_name => username('-noreply'), :password => ENV['VIRTUALMIN_PASSWORD'], :port => 25, :authentication => 'login', :enable_starttls_auto => false}
  end  
  
  has_many :conversations, :dependent => :destroy
  has_many :conversation_posts, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :membership_requests, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :news_summaries, :dependent => :destroy
  has_many :didyouknows, :dependent => :destroy
  has_many :wall_posts, :dependent => :destroy
  has_many :spaces, :dependent => :destroy
  has_many :docs, :dependent => :destroy
  has_many :surveys, :dependent => :destroy
  
  def visible_conversations
    conversations.where(:hidden.ne => true)
  end
  
  def visible_conversation_posts
    conversation_posts.where(:hidden.ne => true)
  end
  
  belongs_to :group_type, index: true
      
  def top_stories(from,to)
    Hash[news_summaries.order_by(:order.asc).map { |news_summary| [news_summary, news_summary.top_stories(from, to)[0..2]] }]
  end
  
  def new_people(from,to)
    Account.where(:id.in => memberships.where(:created_at.gte => from).where(:created_at.lt => to+1).pluck(:account_id)).where(:has_picture => true)
  end
  
  def hot_conversations(from,to)
    visible_conversations.where(:updated_at.gte => from).where(:updated_at.lt => to+1).order_by(:updated_at.desc).select { |conversation| conversation.visible_conversation_posts.count >= (ENV['HOT_CONVERSATION_THRESHOLD'].to_i || 3) }
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
      
  def self.admin_fields
    {
      :slug => :text,
      :description => :text_area,
      :privacy => :radio,
      :default_notification_level => :text,
      :request_intro => :text_area,      
      :request_questions => :text_area,
      :reminder_email => :text_area,
      :invite_email => :text_area,
      :membership_request_thanks_email => :text_area,
      :membership_request_acceptance_email => :text_area,
      :redirect_after_first_profile_save => :text,
      :group_type_id => :lookup,
      :memberships => :collection,
      :conversations => :collection
    }
  end
  
  def self.new_tips
    {
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
  
  def self.human_attribute_name(attr, options={})  
    {
      :default_notification_level => 'Email notification default',
      :slug => 'Name'
    }[attr.to_sym] || super  
  end   
  
  def self.privacies
    {'Open' => 'open', 'Closed' => 'closed', 'Secret' => 'secret'}
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
      
  after_create :queue_setup_mail_accounts_and_forwarder
  def queue_setup_mail_accounts_and_forwarder
    if ENV['HEROKU_OAUTH_TOKEN']
      heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
      heroku.dyno.create(ENV['APP_NAME'], {command: "rake groups:setup_mail_accounts_and_forwarder[#{id}]"})
    else
      setup_mail_accounts_and_forwarder
    end
  end
    
  def setup_mail_accounts_and_forwarder  
    return unless ENV['VIRTUALMIN_IP']
    agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    index = agent.get("https://#{ENV['VIRTUALMIN_IP']}:10000").form_with(:action => '/session_login.cgi') do |f|
      f.user = ENV['VIRTUALMIN_USERNAME']
      f.pass = ENV['VIRTUALMIN_PASSWORD']
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
    form['mailuser'] = "#{self.slug}-inbox"
    form['mailpass'] = ENV['VIRTUALMIN_PASSWORD']
    form['quota'] = 0
    form.submit
    # Add outbound user
    form = add_user_page.form_with(:action => 'save_user.cgi')
    form['mailuser'] = "#{self.slug}-noreply"
    form['mailpass'] = ENV['VIRTUALMIN_PASSWORD']
    form['quota'] = 0
    form.submit    
    # Add pipe
    form = add_alias_page.form_with(:action => 'save_alias.cgi')
    form['complexname'] = "#{self.slug}"
    form.field_with(:name => 'type_0').option_with(:text => /Mailbox of user/).click
    form['val_0'] = self.username('-inbox')
    form.field_with(:name => 'type_1').option_with(:text => /Feed to program/).click
    form['val_1'] = "/notify/#{ENV['APP_NAME']}.php #{slug}"
    form.submit      
  end  
  
  attr_accessor :renamed
  before_validation do
    @renamed = slug_changed?
  end
  after_save :rename
  def rename
    if persisted? and @renamed
      queue_setup_mail_accounts_and_forwarder
      conversation_posts.update_all(imap_uid: nil)
    end
  end
    
  def check!
    return unless ENV['VIRTUALMIN_IP']
    group = self
    imap = Net::IMAP.new(ENV['VIRTUALMIN_IP'])
    imap.authenticate('LOGIN', group.username('-inbox'), ENV['VIRTUALMIN_PASSWORD'])
    imap.select('INBOX')  
    
    # delete messages sent by lumen
    sent_by_lumen = imap.search(['HEADER', 'Sender', group.email('-noreply')])
    if !sent_by_lumen.empty?
      imap.store(sent_by_lumen, "+FLAGS", [:Deleted])
      imap.expunge
    end

    imap.search(["SINCE", Date.yesterday.strftime("%d-%b-%Y"), 'NOT', 'HEADER', 'Sender', group.email('-noreply')]).each do |sequence_id|
      
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
              
    html = body.decoded.force_encoding(charset).encode('UTF-8')              
    html = html.gsub("\n", "<br>\n") if nl2br
    html = html.gsub(/<o:p>/, '')
    html = html.gsub(/<\/o:p>/, '')
    begin
      html = Premailer.new(html, :with_html_string => true, :adapter => 'nokogiri', :input_encoding => 'UTF-8').to_inline_css
    rescue => e
      Airbrake.notify(e)
    end
                                   
    if conversation = ConversationPostBcc.find_by(message_id: mail.in_reply_to).try(:conversation) and conversation.group == group      
      new_conversation = false
      puts "part of conversation id #{conversation.id}"
      [/Respond\s+by\s+replying\s+above\s+this\s+line/, /On.+, .+ wrote:/, /<span.*>From:<\/span>/, '___________','<hr id="stopSpelling">'].each { |pattern|
        html = html.split(pattern).first
      }
    else      
      new_conversation = true
      conversation = group.conversations.create :subject => (mail.subject.blank? ? '(no subject)' : mail.subject), :account => account
      puts "created new conversation id #{conversation.id}"
      return :failed if !conversation.persisted? # failed to find/create a valid conversation - probably a dupe
      ['DISCLAIMER: This e-mail is confidential'].each { |pattern|
        html = html.split(pattern).first
      }
    end
      
    html = Nokogiri::HTML.parse(html)
    html.search('style').remove
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
      
end
