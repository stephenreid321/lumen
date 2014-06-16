class GroupJoinTagship
  include Mongoid::Document
  include Mongoid::Timestamps
    
  belongs_to :group, index: true  
  belongs_to :account_tag, index: true
  
  validates_presence_of :group, :account_tag
  validates_uniqueness_of :group, :scope => :account_tag
    
  def self.fields_for_index
    [:group_id, :account_tag_id]
  end
  
  def self.fields_for_form
    {
      :group_id => :lookup,
      :account_tag_id => :lookup,
    }
  end
    
  def self.lookup
    :id
  end  
  
end
