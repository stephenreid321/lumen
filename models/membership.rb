class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :role, :type => String, :default => 'member'
  field :notification_level, :type => String, :default => 'each'
  field :reminder_sent, :type => Time
  
  belongs_to :account
  belongs_to :group
        
  validates_presence_of :account, :group
  validates_uniqueness_of :account, :scope => :group
      
  def self.fields_for_index
    [:account_id, :group_id, :role, :notification_level]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :group_id => :lookup,
      :notification_level => :select,
      :role => :select
    }
  end
  
  def self.lookup
    :id
  end
  
  def self.notification_levels
    ['none', 'each']
  end
  
  def self.roles
    ['member', 'admin']
  end
  
  def admin?
    role == 'admin'
  end

end
