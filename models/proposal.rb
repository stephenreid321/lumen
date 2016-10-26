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
    
end
