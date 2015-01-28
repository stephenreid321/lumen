class PageView
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  
  field :path, :type => String
  
  before_validation do
    errors.add(:path, 'is invalid') if %w{ico ics}.any? { |x| path.ends_with?(x) }
  end
    
  def self.admin_fields
    {
      :account_id => :lookup,
      :path => :text
    }
  end
  
  def self.by_page
    pages = {}
    PageView.each { |page_view|
      pages[page_view.path] = [] if !pages[page_view.path]
      pages[page_view.path] << page_view
    }
    pages.sort_by { |k,v| -v.count }
  end
  
end
