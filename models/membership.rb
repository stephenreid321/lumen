class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :admin, :type => Boolean
  field :notification_level, :type => String
  field :status, :type => String
  field :reminder_sent, :type => Time
  
  belongs_to :account, index: true
  belongs_to :group, index: true
        
  validates_presence_of :account, :group, :status, :notification_level
  validates_uniqueness_of :account, :scope => :group
      
  def self.fields_for_index
    [:account_id, :group_id, :admin, :status, :notification_level]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :notification_level => :select,
      :admin => :check_box,
      :status => :select      
    }
  end
  
  before_validation :admin_to_boolean
  def admin_to_boolean
    if self.admin == '0'; self.admin = false; elsif self.admin == '1'; self.admin = true; end; return true
  end   
  
  before_validation do
    if self.group and !self.notification_level
      self.notification_level = group.default_notification_level
    end
    if self.account and !self.status
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

end
