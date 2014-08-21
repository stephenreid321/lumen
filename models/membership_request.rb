class MembershipRequest
  include Mongoid::Document
  include Mongoid::Timestamps
    
  belongs_to :account, index: true
  belongs_to :group, index: true
        
  validates_presence_of :account, :group, :status
  
  field :status, :type => String
  field :answers, :type => Array
  
  def answers=(x)
    if x.is_a? String
      super(eval(x))
    else
      super(x)
    end
  end
        
  def self.fields_for_index
    [:account_id, :group_id, :status, :answers, :created_at]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :status => :select,
      :answers => :text_area
    }
  end
    
  def self.statuses
    ['pending', 'accepted', 'rejected']
  end    
  
  def self.lookup
    :id
  end

end
