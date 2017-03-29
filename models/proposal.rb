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
      :details => :wysiwyg,
      :closes_at => :datetime,
      :account_id => :lookup,
      :conversation_id => :lookup,
      :positions => :collection
    }
  end
  
  def closed?
    Time.now > closes_at
  end
  
  after_create do
    conversation_post = conversation.conversation_posts.create!(
      :body => %Q{
        <p style="color: #ccc; text-transform: uppercase; margin-bottom: 5px">Proposal</p>
        <h2 style="margin-top: 0">#{title}</h2>
        <p style="font-size: 12px">Closes #{closes_at}</p>
        <p>#{details}</p>
        <p class="hidden" style="font-size: 12px">State your position at <a href="http://#{Config['DOMAIN']}/conversations/#{conversation.slug}">http://#{Config['DOMAIN']}/conversations/#{conversation.slug}</a></p>},
      :account => account)
    conversation_post.send_notifications!  
  end
    
end
