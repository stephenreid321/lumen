class ListItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :link, :type => String
  field :content, :type => String
  field :address, :type => String
  field :coordinates, :type => Array  
  
  include Geocoder::Model::Mongoid
  geocoded_by :address  
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.geocode || (self.coordinates = nil)
  end  
  
  belongs_to :list, index: true
  belongs_to :account, index: true
  
  has_many :list_item_votes, :dependent => :destroy
  
  validates_presence_of :title, :list, :account
    
  def self.fields_for_index
    [:title, :content, :link, :address, :list_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :title => :text,
      :content => :text,
      :link => :text,
      :address => :text,
      :list_id => :lookup,
      :account_id => :lookup,
      :list_item_votes => :collection
    }
  end
  
  before_validation do
    self.link = "http://#{self.link}" if self.link and !self.link.start_with?('http://')
  end
  
  def self.lookup
    :title
  end
  
  def score
    list_item_votes.map(&:value).sum
  end
  
  def self.edit_hints
    {
      :address => '(if you want this item displayed on a map)'
    }
  end
  
end
