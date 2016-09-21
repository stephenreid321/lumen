class Conversation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group, index: true  
  belongs_to :account, index: true
  
  has_many :conversation_posts, :dependent => :destroy
  accepts_nested_attributes_for :conversation_posts
  has_many :conversation_mutes, :dependent => :destroy
  has_many :conversation_post_bccs, :dependent => :destroy
  has_many :conversation_post_bcc_recipients, :dependent => :destroy
  has_many :conversation_post_read_receipts, :dependent => :destroy
  
  def merge(other_conversation)
    [conversation_posts, conversation_post_bccs, conversation_post_bcc_recipients, conversation_mutes].each { |collection|
      collection.each { |x|
        x.update_attribute(:conversation_id, other_conversation.id)
      }
    }
    self.update_attribute(:hidden, true)
  end
    
  def visible_conversation_posts
    conversation_posts.where(:hidden.ne => true)
  end
  
  field :subject, :type => String
  field :slug, :type => Integer
  field :hidden, :type => Boolean, :default => false
  field :approved, :type => Boolean
  
  index({slug: 1 }, {unique: true})
  
  validates_presence_of :subject, :slug, :group, :account
  validates_uniqueness_of :slug
  
  def tags
    subject.scan(/(?:\s|^)(?:#(?!(?:\d+|\w+?_|_\w+?)(?:\s|$)))(\w+)(?=\s|$)/i).flatten
  end
          
  before_validation :set_slug
  def set_slug
    if !self.slug
      if Conversation.count > 0
        self.slug = Conversation.only(:slug).order_by(:slug.desc).first.slug + 1
      else
        self.slug = 1
      end
    end
  end
  
  attr_accessor :body, :file, :link_title, :link_url, :link_description, :link_picture, :link_player       
  before_validation :set_conversation_post
  def set_conversation_post
    if self.body
      self.body = self.body.gsub("\n","<br />\n") if Config['WALL_STYLE_CONVERSATIONS']
      conversation_post = self.conversation_posts.build body: self.body, account: self.account
      %w{title url description picture player}.each { |x|
        conversation_post.send("link_#{x}=", self.send("link_#{x}"))
      }
      if self.file
        conversation_post.attachments.build file: self.file
      end
    end
  end
    
  before_validation :ensure_not_duplicate
  def ensure_not_duplicate
    if most_recent = Conversation.order_by(:created_at.desc).limit(1).first
      errors.add(:subject, 'is a duplicate') if self.group == most_recent.group and self.subject == most_recent.subject
    end
  end
  
  before_validation do
    if self.new_record? and group.conversations_require_approval
      self.hidden = true
    end
  end
  
  after_create do
    if Config['MAIL_SERVER_ADDRESS'] and group.conversations_require_approval
      group = self.group
      Mail.defaults do
        delivery_method :smtp, group.smtp_settings
      end 
      mail = Mail.new(
        :to => group.admins.map(&:email),
        :from => "#{group.slug} <#{group.email('-noreply')}>",
        :subject => "Conversation requires approval in #{group.slug} on #{Config['SITE_NAME_SHORT']}",
        :body => ERB.new(File.read(Padrino.root('app/views/emails/approval_required.erb'))).result(binding)
      )
      mail.deliver        
    end
    if Config['SLACK_WEBHOOK_URL']
      unless self.group.slack_ignore
        agent = Mechanize.new
        agent.post Config['SLACK_WEBHOOK_URL'], %Q{{"text":"New conversation in #{self.group.name}: <http://#{Config['DOMAIN']}/conversations/#{slug}|#{subject}> #{"(<http://#{Config['DOMAIN']}/groups/#{self.group.slug}/conversations_requiring_approval|requires approval>)" if self.group.conversations_require_approval}", "channel": "#{Config['SLACK_CHANNEL']}", "username": "Lumen", "icon_emoji": ":bulb:"}}, {'Content-Type' => 'application/json'}
      end
    end
  end
    
  def self.admin_fields
    {
      :subject => :text,
      :slug => :text,
      :hidden => :check_box,
      :approved => :check_box,
      :group_id => :lookup,      
      :account_id => :lookup,      
      :conversation_posts => :collection
    }
  end
  
  
  def last_conversation_post
    visible_conversation_posts.order_by(:created_at.desc).first
  end
  
  def participants
    Account.where(:id.in => visible_conversation_posts.map(&:account_id))
  end

end
