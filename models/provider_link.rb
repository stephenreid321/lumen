class ProviderLink
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  
  field :provider, :type => String
  field :provider_uid, :type => String
  field :omniauth_hash, :type => Hash
  
  def access_token
    omniauth_hash['credentials']['token']
  end
    
  validates_presence_of :provider, :provider_uid, :omniauth_hash
  validates_uniqueness_of :provider, :scope => :account_id
  validates_uniqueness_of :provider_uid, :scope => :provider
      
  def self.admin_fields
    {
      :provider => :text,
      :provider_uid => :text,
      :omniauth_hash => :text_area,
      :account_id => :text
    }
  end
  
end
