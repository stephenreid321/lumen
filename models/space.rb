class Space
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String  
  field :description, :type => String
  field :link, :type => String
  field :capacity, :type => Integer
  field :accessibility, :type => String
  field :serves_food, :type => Boolean
  field :serves_alcohol, :type => Boolean
  field :hourly_cost, :type => Integer
  
  field :address, :type => String 
  field :approx, :type => Boolean
  field :coordinates, :type => Array  
  
  include Geocoder::Model::Mongoid
  geocoded_by :address
  reverse_geocoded_by :coordinates
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  alias_method :coordinates_lat, :lat
  alias_method :coordinates_lng, :lng
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
  
  validates_presence_of :name, :address, :coordinates
  
  before_validation :serves_food_to_boolean
  def serves_food_to_boolean
    if self.serves_food == '0'; self.serves_food = false; elsif self.serves_food == '1'; self.serves_food = true; end; return true
  end  

  before_validation :serves_alcohol_to_boolean
  def serves_alcohol_to_boolean
    if self.serves_alcohol == '0'; self.serves_alcohol = false; elsif self.serves_alcohol == '1'; self.serves_alcohol = true; end; return true
  end  
  
  before_validation :approx_to_boolean
  def approx_to_boolean
    if self.approx == '0'; self.approx = false; elsif self.approx == '1'; self.approx = true; end; return true
  end    
    
  before_validation do
    self.link = "http://#{self.link}" if self.link and !(self.link =~ /\Ahttps?:\/\//)
    errors.add(:coordinates, 'must be present') if !coordinates or coordinates.all? { |x| x.blank? }
  end  
  
  def self.accessibilities
    ['Fully accessible', 'Partially accessible', 'Not accessible']
  end
  
  def self.marker_color
    '7FDF73'
  end
  
  def self.fields_for_index
    [:name, :description, :link, :capacity, :accessibility, :serves_food, :serves_alcohol, :hourly_cost, :address, :approx, :coordinates, :group_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :description => :wyiswyg,
      :link => :text,
      :capacity => :number,
      :accessibility => :select,
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
  
  def self.human_attribute_name(attr, options={})  
    {
      :hourly_cost => 'Approximate hourly cost',
      :coordinates => 'Location'
    }[attr.to_sym] || super  
  end   
  
  def self.filtered(spaces, params)
    spaces = spaces.or({:capacity.gte => params[:min_capacity]}, {:capacity => nil}) if params[:min_capacity]        
    spaces = spaces.where(:accessibility.ne => 'Not accessible') if params[:accessible]
    spaces = spaces.where(:serves_food => true) if params[:serves_food]
    spaces = spaces.where(:serves_alcohol => true) if params[:serves_alcohol]
    spaces = spaces.or({:hourly_cost.lte => params[:max_hourly_cost]}, {:hourly_cost => nil}) if params[:max_hourly_cost]
    spaces
  end
    
    
end
