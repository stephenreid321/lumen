class ProviderLink
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
    
  def self.lookup
    :provider
  end
  
  field :provider, :type => String
  field :provider_uid, :type => String
  field :omniauth_hash, :type => Hash
  
  def access_token
    omniauth_hash['credentials']['token']
  end
    
  validates_presence_of :provider, :provider_uid, :omniauth_hash
  validates_uniqueness_of :provider, :scope => :account_id
  validates_uniqueness_of :provider_uid, :scope => :provider
      
  def self.fields_for_index
    [:provider, :provider_uid, :omniauth_hash, :account_id]
  end
  
  def self.fields_for_form
    {
      :provider => :text,
      :provider_uid => :text,
      :omniauth_hash => :text_area,
      :account_id => :text
    }
  end
  
end
