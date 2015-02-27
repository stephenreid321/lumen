class ConversationPost
  include Mongoid::Document
  include Mongoid::Timestamps

  field :body, :type => String
  field :imap_uid, :type => String
  field :message_id, :type => String
  field :hidden, :type => Boolean, :default => false
  
  belongs_to :conversation, index: true
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_many :conversation_post_bccs, :dependent => :destroy
  has_many :conversation_post_bcc_recipients, :dependent => :destroy
  has_many :conversation_post_read_receipts, :dependent => :destroy
  
  if !ENV['BCC_EACH']
    def conversation_post_bcc
      conversation_post_bccs.first
    end
  end
  
  has_many :attachments, :dependent => :destroy
  accepts_nested_attributes_for :attachments
  has_many :plus_ones, :dependent => :destroy
  
  validates_presence_of :body, :account, :conversation, :group
  validates_uniqueness_of :imap_uid, :scope => :group, :allow_nil => true
  
  index({imap_uid: 1 })
  
  before_validation :set_group
  def set_group
    self.group = self.conversation.try(:group)
  end
      
  def self.admin_fields
    {
      :id => {:type => :text, :index => false},
      :body => :wysiwyg,
      :imap_uid => :text,
      :message_id => :text,
      :account_id => :lookup,      
      :conversation_id => :lookup,
      :group_id => :lookup,      
      :hidden => :check_box,      
      :conversation_post_bccs => :collection,
      :conversation_post_read_receipts => :collection      
    }
  end
  
  attr_accessor :file
  before_validation :set_attachment
  def set_attachment
    if self.file
      self.attachments.build file: self.file
      self.file = nil
    end  
  end
  
  def account_name
    account.name
  end
  
  before_validation :check_membership_is_not_muted
  def check_membership_is_not_muted
    errors.add(:account, 'is muted') if self.group.memberships.find_by(account: self.account, muted: true)
  end   
  
  after_create :touch_conversation
  def touch_conversation
    conversation.update_attribute(:updated_at, Time.now) unless conversation.hidden
  end
  
  def didyouknow_replacements(string)
    group = conversation.group
    members = group.members
    string.gsub!('[conversation_url]', "http://#{ENV['DOMAIN']}/conversations/#{conversation.slug}")
    string.gsub!('[members]', "#{m = members.count} #{m == 1 ? 'member' : 'members'}")
    string.gsub!('[upcoming_events]', "#{e = group.events.where(:start_time.gt => Time.now).count} #{e == 1 ? 'upcoming event' : 'upcoming events'}")
    most_recently_updated_account = members.order_by([:has_picture.desc, :updated_at.desc]).first
    string.gsub!('[most_recently_updated_url]', "http://#{ENV['DOMAIN']}/accounts/#{most_recently_updated_account.id}")
    string.gsub!('[most_recently_updated_name]', most_recently_updated_account.name)
    string
  end  
  
  def self.dmarc_fail_domains
    %w{yahoo.com aol.com}
  end

  def from_address
    group = conversation.group
    from = account.email
    if ENV['HIDE_ACCOUNT_EMAIL']
      group.email
    elsif ConversationPost.dmarc_fail_domains.include?(from.split('@').last)
      group.email('-noreply')
    else
      from
    end
  end    
   
  def accounts_to_notify
    Account.where(:id.in => 
        group.memberships.where(:notification_level => 'each').where(:status => 'confirmed').only(:account_id).map(&:account_id) - conversation.conversation_mutes.only(:account_id).map(&:account_id)    
    )
  end
        
  def send_notifications!
    return if conversation.hidden
    if ENV['BCC_EACH'] and ENV['HEROKU_OAUTH_TOKEN']
      heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
      heroku.dyno.create(ENV['APP_NAME'], {command: "rake conversation_posts:send_notifications[#{id}]"})
    else
      self.conversation_post_bccs.create(accounts: accounts_to_notify)
    end
  end
      
  def body_with_replacements
    b = body.gsub(/src="cid:(\S+)"/) { |match|
      begin
        %Q{src="#{attachments.find_by(cid: $1).file.url}"}
      rescue
        nil
      end
    }    
    b = b.gsub(/\[cid:(\S+)\]/) { |match|
      begin
        %Q{<img src="#{attachments.find_by(cid: $1).file.url}">}
      rescue
        nil
      end
    }     
    b = b.gsub(/(<iframe.*><\/iframe>)/) do |match|
      src = Nokogiri::HTML.parse($1).search('iframe').first['src']
      %Q{<a href="#{src}">#{src}</a>}
    end
    b
  end
  
end
