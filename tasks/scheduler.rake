
namespace :cleanup do
  task :organisations => :environment do
    Organisation.each { |organisation|
      organisation.destroy if organisation.affiliations.count == 0      
    }
  end
  task :sectors => :environment do
    Sector.each { |sector|
      sector.destroy if sector.sectorships.count == 0      
    }
  end      
end
task :cleanup => ['cleanup:organisations', 'cleanup:sectors']

namespace :news do
  task :update => :environment do
    NewsSummary.each { |news_summary| news_summary.get_current_digest! }
  end
end

namespace :digests do
  task :daily => :environment do
    Group.each { |group|  
      group.send_digests(:daily)
    }
  end
  task :weekly => :environment do
    if Date.today.wday == 0
      Group.each { |group| 
        group.send_digests(:weekly)
      }
    end
  end
end
