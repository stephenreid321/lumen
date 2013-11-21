if defined? Dragonfly
    
  files_app = Dragonfly[:files].configure_with(:imagemagick) do |c|
    c.url_format = '/media/:job/:basename.:format'
  end

  if Padrino.env == :production
    files_app.datastore = Dragonfly::DataStorage::S3DataStore.new
    files_app.datastore.configure do |d|
      d.bucket_name = ENV['S3_BUCKET_NAME']
      d.access_key_id = ENV['S3_ACCESS_KEY']
      d.secret_access_key = ENV['S3_SECRET']
    end       
  else
    files_app.datastore = Dragonfly::DataStorage::MongoDataStore.new
  end

  files_app.define_macro_on_include(Mongoid::Document, :files_accessor)  
  
  #######
  
  pictures_app = Dragonfly[:pictures].configure_with(:imagemagick) do |c|
    c.url_format = '/media/:job'
  end

  if Padrino.env == :production
    pictures_app.datastore = Dragonfly::DataStorage::MongoDataStore.new
    pictures_app.datastore.configure do |c|
      c.host = ENV['MONGOHQ_URL'].split('@').last.split(':').first
      c.port = ENV['MONGOHQ_URL'].split('@').last.split(':').last.split('/').first
      c.database = ENV['MONGOHQ_URL'].split('/')[3]
      c.username = ENV['MONGOHQ_URL'].split('://').last.split(':').first
      c.password = ENV['MONGOHQ_URL'].split('://').last.split('@').first.split(':').last
    end        
  else
    pictures_app.datastore = Dragonfly::DataStorage::MongoDataStore.new
  end

  pictures_app.define_macro_on_include(Mongoid::Document, :pictures_accessor)  
  
end
