class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  field :file_uid, :type => String
  field :file_name, :type => String
  field :cid, :type => String
  
  belongs_to :conversation_post
        
  validates_presence_of :file, :conversation_post
 
  dragonfly_accessor :file, :app => :files
      
  def self.fields_for_index
    [:conversation_post_id]
  end
  
  def self.fields_for_form
    {
      :conversation_post_id => :lookup,
      :file => :file
    }
  end
  
  def self.lookup
    :id
  end

end
