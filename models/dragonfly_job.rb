class DragonflyJob
  include Mongoid::Document
  include Mongoid::Timestamps

  field :signature, :type => String
  field :uid, :type => String
  
  validates_presence_of :signature, :uid
  validates_uniqueness_of :signature, :uid
    
  def self.admin_fields
    {
      :signature => :text,
      :uid => :text
    }
  end
    
end
