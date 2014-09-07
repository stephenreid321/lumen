class PlusOne
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :conversation_post
  
  validates_uniqueness_of :account, :scope => :conversation_post
    
  def self.fields_for_index
    [:account, :conversation_post]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :conversation_post_id => :lookup
    }
  end
    
end
