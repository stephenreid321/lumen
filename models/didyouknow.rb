class Didyouknow
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :group, index: true   
  
  field :body, :type => String  
  
  validates_presence_of :group, :body
      
  def self.admin_fields
    {
      :group_id => :lookup,
      :body => :text_area
    }
  end
     
end

