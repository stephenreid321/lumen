class ConversationPost
  include Mongoid::Document
  include Mongoid::Timestamps

  field :body, :type => String
  field :mid, :type => String
  field :hidden, :type => Boolean, :default => false
  
  belongs_to :conversation, index: true
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_one :conversation_post_bcc, :dependent => :destroy
  
  has_many :attachments, :dependent => :destroy
      
  validates_presence_of :body, :account, :conversation, :group
  validates_uniqueness_of :mid, :scope => :group, :allow_nil => true
  
  index({mid: 1 })
  
  before_validation :set_group
  def set_group
    self.group = self.conversation.try(:group)
  end
      
  def self.fields_for_index
    [:body, :mid, :hidden, :conversation_id, :account_id, :created_at]
  end
   
  def self.fields_for_form
    {
      :body => :text_area,
      :mid => :text,
      :hidden => :check_box,
      :conversation_id => :lookup,
      :account_id => :lookup
    }
  end
  
  def self.lookup
    :account_name
  end
  
  def account_name
    account.name
  end
  
  after_create :touch_conversation
  def touch_conversation
    conversation.update_attribute(:updated_at, Time.now) unless conversation.hidden
  end
  
  before_validation :hidden_to_boolean
  def hidden_to_boolean
    if self.hidden == '0'; self.hidden = false; elsif self.hidden == '1'; self.hidden = true; end; return true
  end  
    
  def send_notifications!(exclude = [])
    unless conversation.hidden
      emails = self.conversation.group.memberships.where(:notification_level => 'each').where(:status => 'confirmed').map { |membership| membership.account.email.downcase }
      emails = emails - exclude.map(&:downcase) - conversation.conversation_mutes.map { |conversation_mute| conversation_mute.account.email.downcase }
      self.create_conversation_post_bcc(emails: emails)
    end
  end
    
  def body_with_inline_images
    b = body.gsub(/src="cid:(\S+)"/) { |match|
      begin
        %Q{src="http://#{ENV['DOMAIN']}#{attachments.find_by(cid: $1).file.url}"}
      rescue
        nil
      end
    }    
    b = b.gsub(/\[cid:(\S+)\]/) { |match|
      begin
        %Q{<img src="http://#{ENV['DOMAIN']}#{attachments.find_by(cid: $1).file.url}">}
      rescue
        nil
      end
    }     
    b
  end
  
end
