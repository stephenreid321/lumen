class Slide
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model  

  field :image_uid, :type => String 
  field :title, :type => String  
  field :caption, :type => String
  field :link, :type => String   
  field :darken, :type => Boolean
  field :order, :type => Integer

  dragonfly_accessor :image
  
  validates_presence_of :image, :title, :link
    
  def self.admin_fields
    {
      :image => :image,
      :title => :text,
      :caption => :text,
      :link => :text,   
      :darken => :check_box,
      :order => :number
    }
  end
    
end
