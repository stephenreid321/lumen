class ConversationPostReadReceipt
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account, index: true
  belongs_to :conversation_post, index: true
  
  validates_presence_of :account, :conversation_post
  
  field :read, :type => Boolean
      
  def self.admin_fields
    {
      :read => :check_box,
      :account_id => :lookup,
      :conversation_post_id => :lookup
    }
  end
              
end
