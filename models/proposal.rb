class Proposal
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :details, :type => String
  field :closes_at, :type => Time
  
  belongs_to :conversation
  belongs_to :account
  has_many :positions, :dependent => :destroy
  
  validates_presence_of :title, :account, :conversation
  validates_uniqueness_of :conversation_id
    
  def self.admin_fields
    {
      :title => :text,
      :details => :text,
      :closes_at => :datetime,
      :account_id => :lookup,
      :conversation_id => :lookup
    }
  end
  
  def closed?
    Time.now > closes_at
  end
  
  after_create do
    conversation_post = conversation.conversation_posts.create!(
      :body => %Q{<p><a href="http://#{Config['DOMAIN']}/accounts/#{account_id}">#{account.name}</a> created a proposal: <strong>#{title}</strong></p><p>#{details}</p><p style="font-size: 12px">State your position at <a href="http://#{Config['DOMAIN']}/conversations/#{conversation.slug}">http://#{Config['DOMAIN']}/conversations/#{conversation.slug}</a></p>},
      :account => account)
    conversation_post.send_notifications!  
  end
    
end
