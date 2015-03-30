
namespace :groups do
  task :setup_mail_accounts_and_forwarder_via_virtualmin, [:group_id] => :environment do |t, args|
    Group.find(args[:group_id]).setup_mail_accounts_and_forwarder_via_virtualmin
  end  
  
  task :send_welcome_emails, [:group_id] => :environment do |t, args|
    Group.find(args[:group_id]).memberships.where(:welcome_email_pending => true).each(&:send_welcome_email)
  end  
  
end