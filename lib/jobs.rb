
SshJob = Struct.new do(:command)  
  def perform
    Net::SSH.start(Config['MAIL_SERVER_ADDRESS'], Config['MAIL_SERVER_USERNAME'], :password => Config['MAIL_SERVER_PASSWORD']) do |ssh|
      ssh.exec!(command)
    end
  end
end

BccSingleJob = Struct.new(:id) do  
  def perform
    ConversationPost.find(id).bcc_single
  end
end

BccEachJob = Struct.new(:id) do  
  def perform
    ConversationPost.find(id).bcc_each
  end
end

SendWelcomeEmailsJob = Struct.new(:id) do
  def perform
    Group.find(id).send_welcome_emails
  end  
end

SetupMailAccountsAndForwarderViaVirtualminJob = Struct.new(:id) do
  def perform
    Group.find(id).setup_mail_accounts_and_forwarder_via_virtualmin
  end  
end
