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
      if Config['GROUPS_TO_JOIN_ON_FIRST_SIGN_IN'] # deprecated
        Config['GROUPS_TO_JOIN_ON_FIRST_SIGN_IN'].split(',').map(&:strip).each { |slug|
          if group = Group.find_by(slug: slug)
            group.memberships.create :account => account
          end
        }
      end
      Group.where(:join_on_first_sign_in => true).each { |group|
        group.memberships.create :account => account
      }
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
