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
    begin
      page = Mechanize.new.get(self.url)
      self.title = page.title.gsub(' - Google Docs','')
      errors.add(:url, 'is not public') if page.uri.host == 'accounts.google.com'
    rescue; end
  end
      
  def type
    url.include?('/d/') ? url.split('/d/').first.split('/').last : url.split('/')[3]
  end
  
  def self.admin_fields
    {
      :url => :text,
      :title => :text,
      :account_id => :lookup,
      :group_id => :lookup
    }
  end
    
end
