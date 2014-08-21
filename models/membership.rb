class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :admin, :type => Boolean
  field :receive_membership_requests, :type => Boolean  
  field :notification_level, :type => String
  field :status, :type => String
  field :reminder_sent, :type => Time
  
  belongs_to :account, index: true
  belongs_to :group, index: true
        
  validates_presence_of :account, :group, :status, :notification_level
  validates_uniqueness_of :account, :scope => :group
      
  def self.fields_for_index
    [:account_id, :group_id, :admin, :receive_membership_requests, :status, :notification_level]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :admin => :check_box,
      :receive_membership_requests => :check_box,
      :status => :select,
      :notification_level => :select
    }
  end
  
  before_validation :admin_to_boolean
  def admin_to_boolean
    if self.admin == '0'; self.admin = false; elsif self.admin == '1'; self.admin = true; end; return true
  end   
  
  before_validation :receive_membership_requests_to_boolean
  def receive_membership_requests_to_boolean
    if self.receive_membership_requests == '0'; self.receive_membership_requests = false; elsif self.receive_membership_requests == '1'; self.receive_membership_requests = true; end; return true
  end     
  
  before_validation do
    if self.group and !self.notification_level
      self.notification_level = group.default_notification_level
    end
    if self.account and !self.status
      self.status = (account.sign_ins.count == 0 ? 'pending' : 'confirmed')
    end
    self.receive_membership_requests = false unless admin?
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
