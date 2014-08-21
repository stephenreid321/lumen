class MembershipRequest
  include Mongoid::Document
  include Mongoid::Timestamps
    
  belongs_to :account, index: true
  belongs_to :group, index: true
        
  validates_presence_of :account, :group
  validates_uniqueness_of :account, :scope => :group
  
  field :answers, :type => Array
      
  def self.fields_for_index
    [:account_id, :group_id, :answers]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :answers => :text_area
    }
  end
  
  def self.lookup
    :id
  end

end
