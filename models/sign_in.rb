class SignIn
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
    
  def self.admin_fields
    {
      :account_id => :lookup
    }
  end  
  
  after_create do
    if account.sign_ins.count == 1
      account.memberships.where(:status => 'pending').each { |membership| membership.update_attribute(:status, 'confirmed') }
    end
  end
  
end
