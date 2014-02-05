class Marker
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :address, :type => String
  field :coordinates, :type => Array  
  
  include Geocoder::Model::Mongoid
  geocoded_by :address  
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.geocode || (self.coordinates = nil)
  end
  
  belongs_to :group
  belongs_to :account
  
  validates_presence_of :name, :address, :group, :account
    
  def self.fields_for_index
    [:name, :address, :group_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :address => :text_area
    }
  end
    
end
