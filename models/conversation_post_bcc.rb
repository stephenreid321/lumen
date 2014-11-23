class ConversationPostBcc
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :conversation_post, index: true
  
  field :emails, :type => Array
  field :delivered_at, :type => Time
  
  validates_presence_of :emails, :conversation_post
    
  def self.admin_fields
    {
      :emails => :text_area,
      :delivered_at => :datetime,
      :conversation_post_id => :lookup
    }
  end
  
  def read_receipt!
    conversation_post.conversation_post_read_receipts.create(account: Account.find_by(email: /^#{Regexp.escape(emails.first)}$/i))
  end
            
  after_create :send_email
  def send_email
    return unless ENV['VIRTUALMIN_IP'] or ENV['MANDRILL_USERNAME'] or ENV['MAILGUN_USERNAME']
    # set locals for ERB binding
    conversation_post_bcc = self
    conversation_post = conversation_post_bcc.conversation_post
    group = conversation_post.conversation.group
        
    Mail.defaults do
      delivery_method :smtp, group.smtp_settings
    end    
                
    mail = Mail.new
    mail.to = group.email
    mail.from = "#{conversation_post.account.name} <#{conversation_post.from_address}>"
    mail.sender = group.email('-noreply')
    mail.subject = conversation_post.conversation.conversation_posts.count == 1 ? "[#{group.slug}] #{conversation_post.conversation.subject}" : "Re: [#{group.slug}] #{conversation_post.conversation.subject}"
    mail.headers({'Precedence' => 'list', 'X-Auto-Response-Suppress' => 'OOF', 'Auto-Submitted' => 'auto-generated', 'List-Id' => "<#{group.slug}.list-id.#{ENV['MAIL_DOMAIN']}>"})
    mail.html_part do
      content_type 'text/html; charset=UTF-8'
      body ERB.new(File.read(Padrino.root('app/views/emails/conversation_post.erb'))).result(binding)
    end
    conversation_post.attachments.each { |attachment|        
      mail.add_file(:filename => attachment.file_name, :content => attachment.file.data)
    }    
    mail.bcc = emails
    mail.deliver
    
    update_attribute(:delivered_at, Time.now)
  end  
  
end
