class SignIn
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
    
  def self.fields_for_index
    [:account_id, :created_at]
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
