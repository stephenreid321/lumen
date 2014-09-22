class Sectorship
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :organisation, index: true  
  belongs_to :sector, index: true
  
  attr_accessor :sector_name
  before_validation :find_or_create_sector
  def find_or_create_sector
    if sector_name
      created_sector = Sector.find_or_create_by(name: self.sector_name)
      if created_sector.persisted?
        self.sector = created_sector
      end
    end
  end
  
  validates_presence_of :sector, :organisation
    
  def self.admin_fields
    {
      :sector_id => :lookup,
      :organisation_id => :lookup
    }
  end
    
end
