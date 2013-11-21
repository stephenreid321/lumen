class PageView
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  
  field :path
    
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
