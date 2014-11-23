class ConversationPost
  include Mongoid::Document
  include Mongoid::Timestamps

  field :body, :type => String
  field :mid, :type => String
  field :hidden, :type => Boolean, :default => false
  
  belongs_to :conversation, index: true
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_many :conversation_post_bccs, :dependent => :destroy
  has_many :conversation_post_read_receipts, :dependent => :destroy
  
  has_many :attachments, :dependent => :destroy
  has_many :plus_ones, :dependent => :destroy
  
  validates_presence_of :body, :account, :conversation, :group
  validates_uniqueness_of :mid, :scope => :group, :allow_nil => true
  
  index({mid: 1 })
  
  before_validation :set_group
  def set_group
    self.group = self.conversation.try(:group)
  end
      
  def self.admin_fields
    {
      :body => :text_area,
      :mid => :text,
      :hidden => :check_box,
      :conversation_id => :lookup,
      :account_id => :lookup
    }
  end
  
  def account_name
    account.name
  end
  
  after_create :touch_conversation
  def touch_conversation
    conversation.update_attribute(:updated_at, Time.now) unless conversation.hidden
  end
  
  def didyouknow_replacements(string)
    group = conversation.group    
    string.gsub!('[conversation_url]', "http://#{ENV['DOMAIN']}/conversations/#{conversation.slug}")
    string.gsub!('[members]', "#{m = group.members.count} #{m == 1 ? 'member' : 'members'}")
    string.gsub!('[upcoming_events]', "#{e = group.events.where(:start_time.gt => Time.now).count} #{e == 1 ? 'upcoming event' : 'upcoming events'}")
    most_recently_updated_account = group.members.order_by([:has_picture.desc, :updated_at.desc]).first
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
    ConversationPost.dmarc_fail_domains.include?(from.split('@').last) ? group.email('-noreply') : from
  end    
  
  def queue_notifications!
    if ENV['BCC_EACH'] && ENV['HEROKU_OAUTH_TOKEN']
      heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
      heroku.dyno.create(ENV['APP_NAME'], {command: "rake conversation_posts:send_notifications[#{id}]"})
    else
      send_notifications!
    end    
  end
      
  def send_notifications!
    return if conversation.hidden
    emails = self.conversation.group.memberships.where(:notification_level => 'each').where(:status => 'confirmed').map { |membership| membership.account.email.downcase }
    emails = emails - conversation.conversation_mutes.map { |conversation_mute| conversation_mute.account.email.downcase }
    if ENV['BCC_EACH']    
      emails.each { |email|
        self.conversation_post_bccs.create(emails: [email])
      }
    else
      self.conversation_post_bccs.create(emails: emails)
    end
  end
    
  def body_with_inline_images
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
    b
  end
  
end
