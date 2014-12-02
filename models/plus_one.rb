class PlusOne
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  belongs_to :conversation_post
  
  validates_uniqueness_of :account, :scope => :conversation_post
    
  def self.admin_fields
    {
      :account_id => :lookup,
      :conversation_post_id => :lookup
    }
  end
  
  after_create :notify
  def notify
    group = conversation_post.group
    Mail.defaults do
      delivery_method :smtp, group.smtp_settings
    end 
    mail = Mail.new(
      :to => conversation_post.account.email,
      :from => "#{group.slug} <#{group.email('-noreply')}>",
      :reply_to => "#{account.name} <#{account.email}>",
      :subject => "#{account.name} +1'd your post in #{conversation_post.conversation.subject}",
      :body => ERB.new(File.read(Padrino.root('app/views/emails/plus_one.erb'))).result(binding)
    )
    mail.deliver         
  end
    
end
