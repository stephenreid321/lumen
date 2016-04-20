class Venue
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String  
  field :description, :type => String
  field :website, :type => String
  field :capacity, :type => Integer
  field :accessibility, :type => String
  field :serves_food, :type => Boolean
  field :serves_alcohol, :type => Boolean
  field :hourly_cost, :type => Integer
  field :private, :type => Boolean
  
  field :address, :type => String 
  field :approx, :type => Boolean
  field :coordinates, :type => Array  
  
  include Geocoder::Model::Mongoid
  geocoded_by :address
  reverse_geocoded_by :coordinates
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  before_validation do
    if address
      self.approx = false
      self.geocode
    elsif coordinates
      self.approx = true
      self.reverse_geocode
    end
  end  
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  validates_presence_of :name
      
  before_validation do
    self.website = "http://#{self.website}" if self.website and !(self.website =~ /\Ahttps?:\/\//)
    errors.add(:coordinates, 'must be present') if !coordinates or coordinates.all? { |x| x.blank? }
  end  
  
  def self.accessibilities
    ['Fully accessible', 'Partially accessible', 'Not accessible']
  end
  
  def self.marker_color
    '7FDF73'
  end
  
  def self.admin_fields
    {
      :name => :text,
      :description => :wysiwyg,
      :website => :text,
      :capacity => :number,
      :accessibility => :select,
      :private => :check_box,
      :serves_food => :check_box,
      :serves_alcohol => :check_box,
      :hourly_cost => :number,
      :address => :text,
      :approx => :check_box,
      :coordinates => :geopicker,
      :group_id => :lookup,
      :account_id => :lookup
    }
  end
      
end
