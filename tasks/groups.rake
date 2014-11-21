
namespace :groups do
  task :setup_mail_accounts_and_forwarder [:group_id] => :environment do
    Group.find(args[:group_id]).setup_mail_accounts_and_forwarder
  end  
end