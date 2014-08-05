
namespace :languages do
  task :default, [:name, :code] => :environment do |t, args|
    Language.create :name => args[:name], :code => args[:code], :default => true
  end 
end
