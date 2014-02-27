class List
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :order, :type => String
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_many :list_items, :dependent => :destroy
  
  validates_presence_of :title, :group, :account
    
  def self.fields_for_index
    [:title, :order, :group_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :title => :text,
      :order => :radio,
      :group_id => :lookup,
      :account_id => :lookup,
      :list_items => :collection
    }
  end
  
  def self.lookup
    :title
  end
  
  def self.orders
    {
      'Score' => 'score',
      'Title' => 'title',
      'Content' => 'content'
    }
  end
  
end
