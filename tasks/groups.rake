
namespace :groups do
  task :setup_mail_accounts_and_forwarder, [:group_id] => :environment do |t, args|
    Group.find(args[:group_id]).setup_mail_accounts_and_forwarder
  end  
  
  task :send_welcome_emails => :environment do |t, args|
    args.extras.each { |membership_id|
      Membership.find(membership_id).send_welcome_email
    }
  end  
  
end