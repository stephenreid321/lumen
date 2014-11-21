class EmailReceiver < (if ENV['MANDRILL_USERNAME']; Incoming::Strategies::Mandrill; elsif ENV['MAILGUN_USERNAME']; Incoming::Strategies::Mailgun; end)
  def receive(mail)    
    if group = Group.find_by(slug: mail.to.first.split('@').first)
      group.process_mail(mail)
    end
  end
end

