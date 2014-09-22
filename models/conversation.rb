class Conversation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group, index: true  
  belongs_to :account, index: true
  
  has_many :conversation_posts, :dependent => :destroy
  has_many :conversation_mutes, :dependent => :destroy
  
  field :subject, :type => String
  field :slug, :type => Integer
  field :hidden, :type => Boolean, :default => false
  
  index({slug: 1 }, {unique: true})
  
  validates_presence_of :subject, :slug, :group, :account
  validates_uniqueness_of :slug
          
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
  
  before_validation :ensure_not_duplicate
  def ensure_not_duplicate
    if most_recent = Conversation.order_by(:created_at.desc).limit(1).first
      errors.add(:subject, 'is a duplicate') if self.group == most_recent.group and self.subject == most_recent.subject
    end
  end
    
  def self.admin_fields
    {
      :subject => :text,
      :slug => :text,
      :hidden => :check_box,
      :group_id => :lookup,      
      :account_id => :lookup,      
      :conversation_posts => :collection
    }
  end
  
  
  def last_conversation_post
    conversation_posts.order_by(:created_at.desc).first
  end
  
  def participants
    Account.where(:id.in => conversation_posts.where(:hidden.ne => true).map(&:account_id))
  end

end
