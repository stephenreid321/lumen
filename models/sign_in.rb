class SignIn
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
    
  def self.admin_fields
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
