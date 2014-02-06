class Affiliation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  
  belongs_to :account
  belongs_to :organisation  
  
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
  
  after_create do
    account.update_attribute(:affiliated, true)
  end
  before_destroy do
    account.update_attribute(:affiliated, false) if account.affiliations.count == 1
  end
  before_destroy do
    organisation.destroy if organisation.affiliations.count == 1
  end
   
  validates_presence_of :title, :organisation, :account
      
  def self.fields_for_index
    [:title, :organisation_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :title => :text,
      :organisation_id => :lookup,
      :account_id => :lookup
    }
  end
  
  def self.lookup
    :title
  end  
  
end
