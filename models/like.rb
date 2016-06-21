class Like
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account, index: true
  belongs_to :conversation_post, index: true
  
  validates_uniqueness_of :account, :scope => :conversation_post
    
  def self.admin_fields
    {
      :account_id => :lookup,
      :conversation_post_id => :lookup
    }
  end
  
  after_create :notify
  def notify
    if ENV['MAIL_SERVER_ADDRESS']
      group = conversation_post.group
      Mail.defaults do
        delivery_method :smtp, group.smtp_settings
      end 
      mail = Mail.new(
        :to => conversation_post.account.email,
        :from => "#{group.name} <#{group.email('-noreply')}>",
        :subject => "#{account.name} liked your post in #{conversation_post.conversation.subject}",
        :body => ERB.new(File.read(Padrino.root('app/views/emails/like.erb'))).result(binding)
      )
      mail.deliver         
    end
  end
    
end
