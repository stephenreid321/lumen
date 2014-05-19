class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  field :file_uid, :type => String
  field :file_name, :type => String
  field :cid, :type => String
  
  belongs_to :conversation_post, index: true
        
  validates_presence_of :file, :conversation_post
 
  dragonfly_accessor :file
      
  def self.fields_for_index
    [:file_name, :conversation_post_id]
  end
  
  def self.fields_for_form
    {
      :conversation_post_id => :lookup,
      :file => :file,
      :file_name => :text,
      :cid => :text
    }
  end
  
  def self.lookup
    :id
  end

end
