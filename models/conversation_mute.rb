class ConversationMute
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :conversation, index: true
  belongs_to :account, index: true
  
  validates_presence_of :account, :conversation
  validates_uniqueness_of :account, :scope => :conversation
      
  def self.fields_for_index
    [:conversation_id, :account_id, :created_at]
  end
   
  def self.fields_for_form
    {
      :conversation_id => :lookup,
      :account_id => :lookup
    }
  end
  
  def self.lookup
    :id
  end  

end
