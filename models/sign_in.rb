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
  
  def self.by_account
    accounts = {}
    SignIn.each { |sign_in|
      accounts[sign_in.account] = [] if !accounts[sign_in.account]
      accounts[sign_in.account] << sign_in.account
    }
    accounts.sort_by { |k,v| -v.count }
  end  
  
end
