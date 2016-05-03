require 'dragonfly'

Dragonfly.app.configure do    
  plugin :imagemagick
  url_format '/media/:job/:name'    
  datastore :s3, {:bucket_name => ENV['S3_BUCKET_NAME'], :access_key_id => ENV['S3_ACCESS_KEY'], :secret_access_key => ENV['S3_SECRET'], :region => ENV['S3_REGION']}
  secret ENV['DRAGONFLY_SECRET']
  
  define_url do |app, job, opts|    
    app.datastore.url_for((DragonflyJob.find_by(signature: job.signature) || DragonflyJob.create(uid: job.store, signature: job.signature)).uid)
  end

end