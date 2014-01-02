class Organisation
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model

  field :name, :type => String
  field :address, :type => String
  field :website, :type => String
  field :picture_uid  
  
  has_many :events, :dependent => :destroy
  has_many :sectorships, :dependent => :destroy
  accepts_nested_attributes_for :sectorships, allow_destroy: true, reject_if: :all_blank
  
  has_many :affiliations, :dependent => :destroy
  
  def members
    Account.where(:id.in => affiliations.only(:account_id).map(&:account_id))
  end  
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false 
  
  before_validation :tidy_website
  def tidy_website
    if self.website
      if self.website.start_with?('http://')
        self.website = self.website[7..-1]
      end
      if self.website.end_with?('/')
        self.website = self.website[0..-2]
      end
    end
  end
    
  def self.fields_for_index
    [:name, :address]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :address => :text,
      :website => :text,
      :picture => :image,
      :sectorships => :collection,
      :affiliations => :collection
    }
  end
  
  def self.lookup
    :name
  end
  
  # Picture
  dragonfly_accessor :picture, :app => :pictures do
    after_assign :resize_picture
  end
  def resize_picture
    picture.thumb('500x500>')
  end  
  attr_accessor :rotate_picture_by
  before_validation :rotate_picture
  def rotate_picture
    if self.picture and self.rotate_picture_by
      picture.rotate(self.rotate_picture_by)
    end  
  end  
    
end
