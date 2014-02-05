
task :get, :url do |t, args|
    require 'mechanize'
    Mechanize.new.get(args[:url])
end
