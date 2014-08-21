
def path(x)
  open("http://#{ENV['DOMAIN']}#{x}?token=#{Account.find_by(admin: true).generate_secret_token}")
end

namespace :cleanup do
  task :organisations => :environment do
    path '/organisations/cleanup'
  end
  task :sectors => :environment do
    path '/sectors/cleanup'
  end      
end

task :cleanup => ['cleanup:organisations', 'cleanup:sectors']

namespace :news do
  task :update => :environment do
    path '/update_news'
  end
end

namespace :digests do
  task :daily => :environment do
    path '/send_digests/daily'
  end
  task :weekly => :environment do
    if Date.today.wday == 0
      path '/send_digests/weekly'
    end
  end
end
