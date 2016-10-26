class Position
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, :type => String
  field :reason, :type => String
  
  belongs_to :proposal
  belongs_to :account
  
  def self.statuses
    %w{agree abstain disagree block}
  end
  
  validates_presence_of :status
  validates_uniqueness_of :account_id, :scope => :proposal_id
    
  def self.admin_fields
    {
      :status => :select,
      :reason => :text_area,
      :account_id => :lookup,
      :proposal_id => :lookup
    }
  end
    
end
