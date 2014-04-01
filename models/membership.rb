class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :role, :type => String, :default => 'member'
  field :notification_level, :type => String, :default => 'each'
  field :status, :type => String
  field :reminder_sent, :type => Time
  
  belongs_to :account, index: true
  belongs_to :group, index: true
        
  validates_presence_of :account, :group, :status
  validates_uniqueness_of :account, :scope => :group
      
  def self.fields_for_index
    [:account_id, :group_id, :role, :status, :notification_level]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :notification_level => :select,
      :role => :select,
      :status => :select      
    }
  end
  
  before_validation do
    if account
      self.status = (account.sign_ins.count == 0 ? 'pending' : 'confirmed')
    end
  end
    
  def self.lookup
    :id
  end
  
  def self.statuses
    ['pending', 'confirmed']
  end
  
  def self.notification_levels
    ['none', 'each', 'daily', 'weekly']
  end
  
  def self.roles
    ['member', 'admin']
  end
  
  def admin?
    role == 'admin'
  end

end
