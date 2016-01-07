class Slide
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model  

  field :image_uid, :type => String 
  field :title, :type => String  
  field :link, :type => String  
  field :caption, :type => String

  dragonfly_accessor :image
  
  validates_presence_of :image, :title, :link
    
  def self.admin_fields
    {
      :image => :image,
      :title => :text,
      :link => :text,
      :caption => :text
    }
  end
    
end
