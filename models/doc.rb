class Doc
  include Mongoid::Document
  include Mongoid::Timestamps

  field :url, :type => String
  field :title, :type => String
  
  validates_presence_of :url, :title, :account, :group
  validates_format_of :url, :with => /docs\.google\.com/
  
  belongs_to :account
  belongs_to :group
  
  before_validation do    
    self.url = "http://#{self.url}" if self.url and !(self.url =~ /\Ahttps?:\/\//)
    self.title = begin; Mechanize.new.get(self.url).title.gsub(' - Google Docs',''); rescue; end
  end
    
  def self.fields_for_index
    [:url, :title, :account_id, :group_id]
  end
  
  def type
    url.split('/')[3]
  end
  
  def self.fields_for_form
    {
      :url => :text,
      :title => :text,
      :account_id => :lookup,
      :group_id => :lookup
    }
  end
    
end
