class ListItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :link, :type => String
  field :content, :type => String
  
  belongs_to :list
  belongs_to :account
  
  has_many :list_item_votes, :dependent => :destroy
  
  validates_presence_of :title, :list, :account
    
  def self.fields_for_index
    [:title, :content, :list_id, :account_id]
  end
  
  def self.fields_for_form
    {
      :title => :text,
      :content => :text,
      :list_id => :lookup,
      :account_id => :lookup,
      :list_item_votes => :collection
    }
  end
  
  before_validation do
    self.link = "http://#{self.link}" if self.link and !self.link.start_with?('http://')
  end
  
  def self.lookup
    :title
  end
  
  def score
    list_item_votes.map(&:value).sum
  end
  
end
