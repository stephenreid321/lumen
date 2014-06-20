class Group
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String
  field :description, :type => String
  field :privacy, :type => String
  
  index({slug: 1 }, {unique: true})
  
  validates_presence_of :slug, :privacy
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/  
  
  def email(suffix = '')
    "#{self.slug}#{suffix}@#{ENV['MAIL_DOMAIN']}"
  end
      
  def username(suffix = '')
    u = "#{slug}"
    u << suffix
    unless u == (mail_domain_root = ENV['MAIL_DOMAIN'].split('.').first)
      u << '.'
      u << mail_domain_root
    end
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
  
  belongs_to :group_type, index: true
  
  has_many :group_tagged_post_tagships, :dependent => :destroy
  has_many :group_join_tagships, :dependent => :destroy
  
  attr_accessor :tagged_post_account_tag_ids
  before_validation :process_tagged_post_account_tag_ids
  def process_tagged_post_account_tag_ids
    if @tagged_post_account_tag_ids
      group_tagged_post_tagships.destroy_all
      @tagged_post_account_tag_ids.each { |id|
        Group.skip_callback(:validation, :before, :process_tagged_post_account_tag_ids)
        group_tagged_post_tagships.create :account_tag_id => id
        Group.set_callback(:validation, :before, :process_tagged_post_account_tag_ids)        
      }
      @tagged_post_account_tag_ids = nil
    end
  end  
  
  attr_accessor :join_account_tag_ids
  before_validation :process_join_account_tag_ids
  def process_join_account_tag_ids
    if @join_account_tag_ids
      group_join_tagships.destroy_all
      @join_account_tag_ids.each { |id|
        Group.skip_callback(:validation, :before, :process_join_account_tag_ids)
        group_join_tagships.create :account_tag_id => id
        Group.set_callback(:validation, :before, :process_join_account_tag_ids)        
      }
      @join_account_tag_ids = nil
    end
  end  
  
  def tagged_posts
    TaggedPost.where(:id.in => TaggedPostTagship.where(:account_tag_id.in => group_tagged_post_tagships.map(&:account_tag_id)).map(&:tagged_post_id))
  end  
    
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
  
  def admins
    Account.where(:id.in => memberships.where(:role => 'admin').only(:account_id).map(&:account_id))
  end
  
  def twitter_handles
    memberships.map(&:account).map(&:connections).flatten.select { |connection| connection.provider == 'Twitter' }.map { |connection| connection.omniauth_hash['info']['nickname'] }
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
      
  def self.fields_for_index
    [:slug, :privacy, :group_type_id]
  end
  
  def self.fields_for_form
    {
      :slug => :text,
      :description => :text_area,
      :privacy => :radio,
      :group_type_id => :lookup,
      :memberships => :collection,
      :conversations => :collection,
      :group_tagged_post_tagships => :collection
    }
  end
  
  def self.lookup
    :slug
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :slug => 'Name',
      :tagged_post_account_tag_ids => 'Display wall posts with tags',
      :join_account_tag_ids => 'Automatically add people who tag themselves'
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
      
  after_create :setup_mail_accounts_and_forwarder
  def setup_mail_accounts_and_forwarder
    return unless ENV['VIRTUALMIN_IP']
    agent = Mechanize.new
    agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    index = agent.get("https://#{ENV['VIRTUALMIN_IP']}:10000").form_with(:action => '/session_login.cgi') do |f|
      f.user = ENV['VIRTUALMIN_USERNAME']
      f.pass = ENV['VIRTUALMIN_PASSWORD']
    end.submit
    form = index.frame_with(:src => 'left.cgi').click.form_with(:action =>'left.cgi')
    form.field_with(:name => 'dom').option_with(:text => /#{ENV['MAIL_DOMAIN'][0..9]}/).click
    domain_page = form.submit
    users_page = domain_page.link_with(:text => 'Edit Users').click
    add_user_page = users_page.link_with(:text => 'Add a user to this server.').click
    aliases_page = domain_page.link_with(:text => 'Edit Mail Aliases').click
    add_alias_page = aliases_page.link_with(:text => 'Add an alias to this domain.').click.link_with(:text => 'Advanced mode').click
    # Add inbound user
    form = add_user_page.form_with(:action => 'save_user.cgi')
    form['mailuser'] = self.slug
    form['mailpass'] = ENV['VIRTUALMIN_PASSWORD']
    form['quota'] = 0
    form.checkbox_with(:name => /forward/).check
    form['forwardto'] = "#{self.slug}-pipe@#{ENV['MAIL_DOMAIN']}"
    form.submit
    # Add outbound user
    form = add_user_page.form_with(:action => 'save_user.cgi')
    form['mailuser'] = "#{self.slug}-noreply"
    form['mailpass'] = ENV['VIRTUALMIN_PASSWORD']
    form['quota'] = 0
    form.submit    
    # Add pipe
    form = add_alias_page.form_with(:action => 'save_alias.cgi')
    form['complexname'] = "#{self.slug}-pipe"
    form.field_with(:name => 'type_0').option_with(:text => /Feed to program/).click
    form['val_0'] = "/notify/#{ENV['HEROKU_APP_NAME']}.php #{slug}"
    form.submit      
  end  
  
  def check!
    group = self
    imap = Net::IMAP.new(ENV['VIRTUALMIN_IP'])
    imap.authenticate('LOGIN', group.username, ENV['VIRTUALMIN_PASSWORD'])
    imap.select('INBOX')
    imap.search(["SINCE", Date.yesterday.strftime("%d-%b-%Y")]).each do |sequence_id|
                
      envelope = imap.fetch(sequence_id, "ENVELOPE")[0].attr["ENVELOPE"]        
      sender = "#{envelope.sender[0].mailbox}@#{envelope.sender[0].host}"
      from = "#{envelope.from[0].mailbox}@#{envelope.from[0].host}"
                                  
      # delete notifications sent by/to the group        
      if sender == group.email('-noreply')
        imap.store(sequence_id, "+FLAGS", [:Deleted])
        next
      end
      
      # skip messages we've already dealt with
      message_id = imap.fetch(sequence_id,'UID')[0].attr['UID']
      if group.conversation_posts.find_by(mid: message_id)
        next
      end
      
      # delete messages from people that aren't in the group
      account = Account.find_by(email: /^#{Regexp.escape(from)}$/i)     
      if !account or !account.memberships.find_by(group: group)
        Mail.defaults do
          delivery_method :smtp, group.smtp_settings
        end 
        mail = Mail.new(
          :to => from,
          :bcc => ENV['HELP_ADDRESS'],
          :from => "#{group.slug} <#{group.email('-noreply')}>",
          :subject => "Delivery failed: #{envelope.subject}",
          :body => ERB.new(File.read(Padrino.root('app/views/emails/delivery_failed.erb'))).result(binding)
        )
        mail.deliver! 
        imap.store(sequence_id, "+FLAGS", [:Deleted])
        next
      end          
              
      msg = imap.fetch(sequence_id,'RFC822')[0].attr['RFC822']          
      mail = Mail.read_from_string msg                    
              
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
                             
      if (
          html.match(/Respond\s+by\s+replying\s+above\s+this\s+line/) and
            (conversation_url_match = html.match(/http:\/\/#{ENV['DOMAIN']}\/conversations\/(\d+)/)) and
            conversation = group.conversations.find_by(slug: conversation_url_match[-1])
        )
        new_conversation = false
        [/Respond\s+by\s+replying\s+above\s+this\s+line/, /On.+, .+ wrote:/, /<span.*>From:<\/span>/, '___________', '<div.*#B5C4DF.*>'].each { |pattern|
          html = html.split(pattern).first
        }
      else
        new_conversation = true
        conversation = group.conversations.create :subject => (mail.subject.blank? ? '(no subject)' : mail.subject)                  
        next if !conversation.persisted? # failed to find/create a valid conversation - probably a dupe
        ['DISCLAIMER: This e-mail is confidential'].each { |pattern|
          html = html.split(pattern).first
        }
      end
      
      html = Nokogiri::HTML.parse(html)
      html.search('style').remove
      html = html.search('body').inner_html
                     
      conversation_post = conversation.conversation_posts.create :body => html, :account => account, :mid => message_id                   
      if !conversation_post.persisted? # failed to create the conversation post
        conversation.destroy if new_conversation
        next
      end
      mail.attachments.each do |attachment|
        conversation_post.attachments.create :file => attachment.body.decoded, :file_name => attachment.filename, :cid => attachment.cid
      end                        
      conversation_post.send_notifications!(([mail.to].flatten + [mail.cc].flatten).compact.uniq)
      
      imap.store(sequence_id, "+FLAGS", [:Seen])
    end 
    imap.expunge
    imap.disconnect
  end
      
end
