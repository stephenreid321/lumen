    
Dragonfly.app.configure do
  plugin :imagemagick
  url_format '/media/:job/:name'
  
  case Padrino.env
  when :development, :test
    datastore :mongo    
  when :production
    datastore :s3, {:bucket_name => ENV['S3_BUCKET_NAME'], :access_key_id => ENV['S3_ACCESS_KEY'], :secret_access_key => ENV['S3_SECRET']}
  end       
      
end
