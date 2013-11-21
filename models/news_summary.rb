class NewsSummary
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :url, :type => String
  field :selector, :type => String  
  field :body, :type => String  
  field :order, :type => Integer
  
  validates_presence_of :title, :url, :selector, :body
    
  def self.fields_for_index
    [:title, :url, :selector,  :body, :order]
  end
  
  def self.fields_for_form
    {
      :title => :text,
      :url => :text,
      :selector => :text,
      :body => :text_area,      
      :order => :text   
    }
  end
  
  before_validation :set_body  
  def set_body
    self.body = Mechanize.new.get(self.url).search(self.selector).to_s
  end
  
  def fetch!
    set_body; save
  end
  
end