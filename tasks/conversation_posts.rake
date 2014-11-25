
namespace :conversation_posts do
  
  task :send_notifications, [:conversation_post_id] => :environment do |t, args|
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
    conversation_post = ConversationPost.find(args[:conversation_post_id])
    conversation_post.emails_to_notify { |email|
      puts "starting dyno for #{email}"
      heroku.dyno.create(ENV['APP_NAME'], {command: "rake conversation_posts:create_bcc[#{conversation_post.id},#{email}]"})      
    }
  end  
  
  task :create_bcc, [:conversation_post_id, :email] => :environment do |t, args|
    puts "creating bcc for #{args[:email]}"
    ConversationPost.find(args[:conversation_post_id]).conversation_post_bccs.create(emails: [args[:email]])
  end
  
end