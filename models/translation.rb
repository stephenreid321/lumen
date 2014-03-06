class Translation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :key, :type => String
  field :value, :type => String  
  
  index({key: 1 }, {unique: true})
  
  validates_presence_of :key
  validates_uniqueness_of :key
    
  def self.fields_for_index
    [:key, :value]
  end
  
  def self.fields_for_form
    {
      :key => :text,
      :value => :text
    }
  end
      
end
