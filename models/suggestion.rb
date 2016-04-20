class Suggestion
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :account

  field :to, :type => String 
  field :subject, :type => String  
  field :body, :type => Boolean
  
  validates_presence_of :to, :account, :subject, :body
  validates_format_of :to, :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i
    
  def self.admin_fields
    {
      :to => :text,
      :account_id => :lookup,
      :subject => :text,
      :body => :wysiwyg
    }
  end
  
  after_create do
    Mail.defaults do
      delivery_method :smtp, Account.smtp_settings
    end
      
    mail = Mail.new
    mail.to = self.to
    mail.from = "#{account.name} <#{account.email}>"
    mail.subject = self.subject
    b = self.body
    mail.html_part do
      content_type 'text/html; charset=UTF-8'
      body b
    end
    mail.deliver    
  end
    
end
