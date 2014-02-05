    
Dragonfly.app(:files).configure do
  plugin :imagemagick
  url_format '/media/:job/:name'
  
  case Padrino.env
  when :development
    datastore :mongo    
  when :production
    datastore :s3, {:bucket_name => ENV['S3_BUCKET_NAME'], :access_key_id => ENV['S3_ACCESS_KEY'], :secret_access_key => ENV['S3_SECRET']}
  end       
      
end
  
#######
  
Dragonfly.app(:pictures).configure do
  plugin :imagemagick  
  url_format '/media/:job'

  case Padrino.env
  when :development
    datastore :mongo    
  when :production
    datastore :mongo, {
      :host => ENV['MONGOHQ_URL'].split('@').last.split(':').first,
      :port => ENV['MONGOHQ_URL'].split('@').last.split(':').last.split('/').first,
      :database => ENV['MONGOHQ_URL'].split('/')[3],
      :username => ENV['MONGOHQ_URL'].split('://').last.split(':').first,
      :password => ENV['MONGOHQ_URL'].split('://').last.split('@').first.split(':').last
    }
  end        

end
