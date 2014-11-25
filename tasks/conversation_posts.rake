
namespace :conversation_posts do
  
  task :send_notifications, [:conversation_post_id] => :environment do |t, args|
    
    conversation_post = ConversationPost.find(args[:conversation_post_id])
        
    array = conversation_post.emails_to_notify
    no_of_threads = 10
    
    slice_size = (array.length/Float(no_of_threads)).ceil
    slices = array.each_slice(slice_size).to_a
    puts "splitting into #{slices.length} groups of #{slices.map(&:length).join(', ')}"
    threads = []

    slices.each_with_index { |slice, i|
      threads << Thread.new(slice, i) do |slice, i|
        slice.each { |email|
          conversation_post.conversation_post_bccs.create(emails: email)
        }      
      end
    }
    threads.each { |thread| thread.join }

  end  
  
end