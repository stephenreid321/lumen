class Language
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :code, :type => String
  field :default, :type => Boolean
  
  has_many :translations, :dependent => :destroy
  has_many :accounts, :dependent => :nullify
    
  validates_presence_of :name, :code
  validates_uniqueness_of :name
  validates_uniqueness_of :code
  validates_uniqueness_of :default, :if => :default
  
  before_validation do
    errors.add(:code, 'must be two lowercase letters') unless code and code == code.downcase and code.length == 2
  end
    
  def self.fields_for_index
    [:name, :code, :default]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :code => :text,
      :default => :check_box,
      :translations => :collection,
      :accounts => :collection
    }
  end
  
  def self.default
    find_by(default: true)
  end
  
  def self.lookup
    :name
  end
         
end
