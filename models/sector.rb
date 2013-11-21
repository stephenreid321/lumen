class Sector
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  has_many :sectorships, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
    
  def self.fields_for_index
    [:name]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :sectorships => :collection
    }
  end
  
  def self.lookup
    :name
  end
  
  def members
    Account.where(:id.in => sectorships.map(&:organisation).map(&:affiliations).flatten.map(&:account_id))
  end
  
end
