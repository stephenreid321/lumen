class ListItemVote
  include Mongoid::Document
  include Mongoid::Timestamps

  field :value, :type => Integer
  
  belongs_to :list_item, index: true
  belongs_to :account, index: true
  
  validates_presence_of :value, :list_item, :account
    
  def self.fields_for_index
    [:value, :list_item_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :value => :text,
      :list_item_id => :lookup,
      :account_id => :lookup
    }
  end
  
  def self.lookup
    :summary
  end
  
  def summary
    "#{account.name}: #{value}"
  end
  
end
