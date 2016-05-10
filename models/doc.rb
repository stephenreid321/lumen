class Doc
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model

  field :url, :type => String
  field :title, :type => String
  field :file_uid, :type => String
  field :file_name, :type => String  
  
  validates_presence_of :account, :group
  validates_format_of :url, :with => /google\.com/, :allow_nil => true
  
  belongs_to :account, index: true
  belongs_to :group, index: true
  
  dragonfly_accessor :file
  
  before_validation do    
    if !self.url and !self.file
      errors.add(:url, 'or file must be present')
    end
    if self.url and self.file
      errors.add(:file, 'cannot be present if you provide a URL')
    end    
    if self.url      
      self.url = "http://#{self.url}" if !(self.url =~ /\Ahttps?:\/\//)
      if page = begin; Mechanize.new.get(self.url); rescue; errors.add(:url, 'not found'); nil; end      
        errors.add(:url, 'is not public') if page.uri.host == 'accounts.google.com'
        self.title = page.title.gsub(' - Google Docs','').gsub(' - Google Drive','').gsub(' - Google Sheets', '')        
      end
    end
  end
      
  def type
    return 'folder' if url.include?('folderview')
    url.include?('/d/') ? url.split('/d/').first.split('/').last : url.split('/')[3]
  end
  
  def self.admin_fields
    {
      :url => :text,
      :title => :text,
      :file => :file,
      :file_name => :text,      
      :account_id => :lookup,
      :group_id => :lookup      
    }
  end
    
end
