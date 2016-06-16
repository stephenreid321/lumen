class ConversationPostReadReceipt
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :account, index: true
  belongs_to :conversation_post, index: true
  belongs_to :conversation, index: true
  belongs_to :group, index: true
  
  field :web, :type => Boolean
  
  before_validation do    
    self.conversation = self.conversation_post.conversation if self.conversation_post
    self.group = self.conversation.group if self.conversation
  end
  
  validates_presence_of :account, :conversation_post
  validates_uniqueness_of :account, :scope => :conversation_post
  
  def summary
    account.name
  end
        
  def self.admin_fields
    {
      :summary => {:type => :text, :index => false, :edit => false},
      :account_id => :lookup,
      :conversation_post_id => :lookup,
      :web => :check_box
    }
  end
              
end
