class ConversationPostBcc
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :conversation_post
  
  field :emails, :type => Array
  
  validates_presence_of :emails, :conversation_post
    
  def self.fields_for_index
    [:emails, :conversation_post_id]
  end
  
  def self.fields_for_form
    {
      :emails => :text_area
    }
  end
    
  def self.lookup
    :id
  end
    
  def go!
    
    this = self
    group = this.conversation_post.conversation.group
    
    Mail.defaults do
      delivery_method :smtp, { :address => group.smtp_server, :port => group.smtp_port, :authentication => group.smtp_authentication, :enable_ssl => group.smtp_ssl, :user_name => group.smtp_username, :password => group.smtp_password }
    end    
        
    x = %Q{
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <style>
      body, p \{ font-family: "Helvetica Neue", Calibri, Helvetica, Arial, sans-serif; \}
      p.MsoNormal \{ margin-top: 0 !important; margin-bottom: 0 !important; padding-top: 0 !important; padding-bottom: 0 !important \}
    </style>
</head>
<body>
    <span style="font-size: 80%">Respond by replying above this line or visit <a href="http://#{ENV['DOMAIN']}/conversations/#{conversation_post.conversation.slug}">http://#{ENV['DOMAIN']}/conversations/#{conversation_post.conversation.slug}</a></span>
    <br /><br />
    #{conversation_post.body_with_inline_images}
    #{conversation_post.thread}
    <hr style="border: 0; background-color: #ddd" />  
    <span style="font-size: 80%"><a href="http://#{ENV['DOMAIN']}/groups/#{group.slug}/notification_level/none">Stop receiving email notifications from #{group.imap_address}</a></span>
</body>
</html>
    }
        
    mail = Mail.new
    mail.to = group.imap_address,
    mail.from = "#{conversation_post.account.name} <#{conversation_post.account.email}>"
    mail.sender = group.smtp_address
    mail.subject = conversation_post.conversation.conversation_posts.count == 1 ? "[#{group.slug}] #{conversation_post.conversation.subject}" : "Re: [#{group.slug}] #{conversation_post.conversation.subject}"
    mail.headers({'Precedence' => 'list', 'X-Auto-Response-Suppress' => 'OOF', 'Auto-Submitted' => 'auto-generated', 'List-Id' => "<#{group.slug}.list-id.#{ENV['MAIL_DOMAIN']}>"})
    mail.html_part do
      content_type 'text/html; charset=UTF-8'
      body x
    end
    conversation_post.attachments.each { |attachment|        
      mail.add_file(:filename => attachment.file_name, :content => attachment.file.data)
    }
    
    mail.bcc = emails
    logger.info "Delivering #{mail.subject} to #{mail.bcc}"  
    mail.deliver!   
  end  
  
  after_create :go!
  
end
