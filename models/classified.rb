class Classified
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, :type => String
  field :description, :type => String
  
  def self.types
    ['Request', 'Offer']
  end
  
  validates_presence_of :account, :group, :description
  validates_length_of :description, maximum: (Config['MAX_CLASSIFIED_LENGTH'] ? Config['MAX_CLASSIFIED_LENGTH'].to_i : 150)
  
  belongs_to :account, index: true
  belongs_to :group, index: true
  
  def self.admin_fields
    {
      :type => :select,
      :description => :text,      
      :account_id => :lookup,
      :group_id => :lookup      
    }
  end
    
end
