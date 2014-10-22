Dragonfly.app.configure do    
  plugin :imagemagick
  url_format '/media/:job/:name'    
  datastore :s3, {:bucket_name => ENV['S3_BUCKET_NAME'], :access_key_id => ENV['S3_ACCESS_KEY'], :secret_access_key => ENV['S3_SECRET']}   
  secret ENV['DRAGONFLY_SECRET']
  
  define_url do |app, job, opts|    
    dragonfly_job = DragonflyJob.find_by(signature: job.signature) || (uid = job.store; DragonflyJob.create!(uid: uid, signature: job.signature))
    app.datastore.url_for(dragonfly_job.uid)
  end

end