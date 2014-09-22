class Affiliation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
    
  belongs_to :account, index: true
  belongs_to :organisation, index: true  
    
  attr_accessor :organisation_name
  before_validation :find_or_create_organisation
  def find_or_create_organisation
    if organisation_name
      created_organisation = Organisation.find_or_create_by(name: self.organisation_name)
      if created_organisation.persisted?
        self.organisation = created_organisation
      end
    end
  end
       
  validates_presence_of :title, :organisation, :account
      
  def self.admin_fields
    {
      :title => :text,
      :organisation_id => :lookup,
      :account_id => :lookup
    }
  end
  
end
