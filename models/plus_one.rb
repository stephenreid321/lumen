class PlusOne
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :conversation_post
  
  validates_uniqueness_of :account, :scope => :conversation_post
    
  def self.admin_fields
    {
      :account_id => :lookup,
      :conversation_post_id => :lookup
    }
  end
    
end
