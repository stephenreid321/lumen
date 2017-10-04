class Membership
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :admin, :type => Boolean
  field :receive_membership_requests, :type => Boolean  
  field :notification_level, :type => String
  field :status, :type => String
  field :reminder_sent, :type => Time
  field :welcome_email_pending, :type => Boolean
  field :muted, :type => Boolean
  
  belongs_to :added_by, index: true, class_name: "Account", inverse_of: :memberships_added
  belongs_to :account, index: true, class_name: "Account", inverse_of: :memberships
  belongs_to :group, index: true
          
  validates_presence_of :account, :group, :status, :notification_level
  validates_uniqueness_of :account, :scope => :group
      
  def self.admin_fields
    {
      :summary => {:type => :text, :index => false, :edit => false},
      :account_id => :lookup,
      :group_id => :lookup,
      :added_by_id => :lookup,
      :admin => :check_box,
      :receive_membership_requests => :check_box,
      :reminder_sent => :datetime,
      :welcome_email_pending => :check_box,
      :muted => :check_box,
      :status => :select,
      :notification_level => :select
    }
  end
  
  def summary
    "#{self.account.name} - #{self.group.name}"
  end  
        
  before_validation do    
    self.receive_membership_requests = false unless admin?
    if self.group and !self.notification_level
      self.notification_level = group.default_notification_level
    end
    if self.account and !self.status
      self.status = (account.sign_ins.count == 0 ? 'pending' : 'confirmed')
    end
    
    errors.add(:account, 'is prevented from having new memberships') if self.account.prevent_new_memberships and !self.account.groups_to_join
  end
  
  def self.statuses
    ['pending', 'confirmed']
  end
  
  def self.notification_levels
    ['none', 'each', 'daily', 'weekly']
  end
  
  def send_welcome_email
    group = self.group
    Mail.defaults do
      delivery_method :smtp, group.smtp_settings
    end    
      
    sign_in_details = ''
    if status == 'pending'
      sign_in_details << "You need to sign in to start receiving email notifications. "
    end
        
    if account.sign_ins.count == 0
      password = Account.generate_password(8)
      account.update_attribute(:password, password) 
      sign_in_details << "Sign in at http://#{Config['DOMAIN']}/sign_in with the email address #{account.email} and the password #{password}"
    else
      sign_in_details << "Check it out at http://#{Config['DOMAIN']}/groups/#{group.slug}."
    end    
                               
    mail = Mail.new
    mail.to = account.email
    mail.from = "#{group.slug} <#{group.email('-noreply')}>"
    mail.subject = group.invite_email_subject

    content = group.invite_email
    .gsub('[firstname]',account.name.split(' ').first)
    .gsub('[admin]', added_by.try(:name))
    .gsub('[sign_in_details]', sign_in_details) 
    
    html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body ERB.new(File.read(Padrino.root('app/views/layouts/email.erb'))).result(binding)     
    end    
    mail.html_part = html_part     
    
    mail.deliver 
    update_attribute(:welcome_email_pending, false)
  end

end
