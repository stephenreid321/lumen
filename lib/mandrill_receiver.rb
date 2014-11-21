class EmailReceiver < Incoming::Strategies::Mandrill
  def receive(mail)    
    if group = Group.find_by(slug: mail.to.first.split('@').first)
      group.process_mail(mail)
    end
  end
end