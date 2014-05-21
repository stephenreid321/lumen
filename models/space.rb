class Space
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String  
  field :description, :type => String
  field :link, :type => String
  field :capacity, :type => Integer
  
  field :address, :type => String 
  field :coordinates, :type => Array  
  
  include Geocoder::Model::Mongoid
  reverse_geocoded_by :coordinates
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.reverse_geocode || (self.address = nil)
  end  
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  validates_presence_of :name, :coordinates
    
  before_validation do
    self.link = "http://#{self.link}" if self.link and !(self.link =~ /\Ahttps?:\/\//)
    errors.add(:coordinates, 'must be present') if coordinates.all? { |x| x.blank? }
  end  
  
  def self.marker_color
    '7FDF73'
  end
  
  def self.fields_for_index
    [:name, :coordinates, :description, :link, :address, :group_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :description => :text_area,
      :link => :text,
      :group_id => :lookup,
      :account_id => :lookup
    }
  end
    
end
