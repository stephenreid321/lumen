
namespace :conversation_posts do
  task :send_notifications, [:conversation_post_id] => :environment do |t, args|
    ConversationPost.find(args[:conversation_post_id]).send_notifications!
  end  
end