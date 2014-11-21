if ENV['MANDRILL_USERNAME']

  class EmailReceiver < Incoming::Strategies::Mandrill
    def receive(mail)    
      Group.find_by(slug: mail.to.first.split('@').first).try(:process_mail, mail)
    end
  end

elsif ENV['MAILGUN_USERNAME']
  
  class EmailReceiver < Incoming::Strategies::Mailgun
    setup :api_key => ENV['MAILGUN_APIKEY']
    def receive(mail)    
      Group.find_by(slug: mail.to.first.split('@').first).try(:process_mail, mail)
    end
  end

end
