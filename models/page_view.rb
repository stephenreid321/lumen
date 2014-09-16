class PageView
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  
  field :path, :type => String
  
  before_validation do
    errors.add(:path, 'is invalid') if %w{ico ics}.any? { |x| path.ends_with?(x) }
  end
    
  def self.fields_for_index
    [:account_id, :path, :created_at]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup
    }
  end
  
  def self.filter_options
    {
      :o => 'created_at',
      :d => 'desc'
    }    
  end
  
end
