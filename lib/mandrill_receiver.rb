class EmailReceiver < Incoming::Strategies::Mandrill
  def receive(mail)
    %(Got message from #{mail.to.first} with subject "#{mail.subject}")
  end
end