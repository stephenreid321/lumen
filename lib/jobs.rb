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
