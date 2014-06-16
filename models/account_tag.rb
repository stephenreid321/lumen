class AccountTag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  has_many :account_tagships, :dependent => :destroy
  has_many :tagged_post_tagships, :dependent => :destroy
  
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
      :account_tagships => :collection,
      :tagged_post_tagships => :collection
    }
  end
  
  def self.lookup
    :name
  end
    
end
