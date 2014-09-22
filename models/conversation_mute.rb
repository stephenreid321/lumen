class ConversationMute
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :conversation, index: true
  belongs_to :account, index: true
  
  validates_presence_of :account, :conversation
  validates_uniqueness_of :account, :scope => :conversation
      
  def self.admin_fields
    {
      :conversation_id => :lookup,
      :account_id => :lookup
    }
  end
  
end
