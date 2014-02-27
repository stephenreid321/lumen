class List
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :order, :type => String, :default => 'score'
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_many :list_items, :dependent => :destroy
  
  def number_content
    order == 'content' and list_items.all? { |list_item| list_item.content && list_item.content.to_i.to_s == list_item.content }
  end
  
  def list_items_sorted
    items = list_items.sort { |a,b|
      x = a.send(:"#{order}")      
      y = b.send(:"#{order}")
      (x = x.to_i; y = y.to_i) if number_content
      x && y ? x <=> y : x ? -1 : 1
    }
    items.reverse! if order == 'score'
    items
  end
  
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
