class Survey
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :intro, :type => String
  
  belongs_to :group
  belongs_to :account
  
  has_many :questions, :dependent => :destroy
  accepts_nested_attributes_for :questions, allow_destroy: true, reject_if: :all_blank
  
  has_many :answers, :dependent => :destroy
  
  validates_presence_of :title, :group, :account
    
  def self.fields_for_index
    [:title, :intro, :group_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :title => :text,
      :intro => :text_area,
      :group_id => :lookup,
      :account_id => :lookup,
      :questions => :collection
    }
  end
  
  def takers
    Account.where(:id.in => answers.only(&:account_id).map(&:account_id))
  end
  
  def self.lookup
    :title
  end
    
end
