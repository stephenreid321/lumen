class AccountTag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  has_many :account_tagships, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  before_validation do
    self.name = self.name.strip.downcase if self.name
  end
    
  def self.fields_for_index
    [:name]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :account_tagships => :collection
    }
  end
  
  def self.lookup
    :name
  end
  
  def self.names(accounts)
    where(:id.in => AccountTagship.where(:account_id.in => accounts.only(&:id).map(&:id)).only(&:account_tag_id).map(&:account_tag_id)).order_by(:name.asc).only(&:name).map(&:name)
  end  
    
end
