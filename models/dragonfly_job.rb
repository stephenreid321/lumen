class DragonflyJob
  include Mongoid::Document
  include Mongoid::Timestamps

  field :signature, :type => String
  field :uid, :type => String
  
  validates_presence_of :signature, :uid
  validates_uniqueness_of :signature, :uid
    
  def self.fields_for_index
    [:signature, :uid, :created_at]
  end
  
  def self.fields_for_form
    {
      :signature => :text,
      :uid => :text
    }
  end
    
end
