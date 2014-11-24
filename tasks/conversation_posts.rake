
namespace :conversation_posts do
  task :send_notifications, [:conversation_post_id] => :environment do |t, args|
    ConversationPost.find(args[:conversation_post_id]).send_notifications!
  end  
  
  task :create_bcc, [:conversation_post_id, :email] => :environment do |t, args|
    ConversationPost.find(args[:conversation_post_id]).conversation_post_bccs.create(emails: [args[:email]])
  end
  
end