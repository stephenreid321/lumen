class Workoff
  def self.workoff    
    if Config['HEROKU_WORKOFF'] and Config['HEROKU_OAUTH_TOKEN']
      heroku = PlatformAPI.connect_oauth(Config['HEROKU_OAUTH_TOKEN'])   
      heroku.dyno.create(Config['APP_NAME'], {command: "rake jobs:workoff"})
    end
  end
end

BccSingleJob = Struct.new(:id) do  
  def enqueue
    Workoff.workoff 
  end
  def perform
    ConversationPost.find(id).bcc_single
  end
end

BccEachJob = Struct.new(:id) do  
  def enqueue
    Workoff.workoff 
  end
  def perform
    ConversationPost.find(id).bcc_each
  end
end

SendWelcomeEmailsJob = Struct.new(:id) do
  def enqueue
    Workoff.workoff
  end  
  def perform
    Group.find(id).send_welcome_emails
  end  
end

SetupMailAccountsAndForwarderViaVirtualminJob = Struct.new(:id) do
  def enqueue
    Workoff.workoff
  end  
  def perform
    Group.find(id).setup_mail_accounts_and_forwarder_via_virtualmin
  end  
end
