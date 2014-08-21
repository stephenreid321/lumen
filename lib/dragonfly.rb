Dragonfly.app.configure do    
  plugin :imagemagick
  url_format '/media/:job/:name'    
  datastore :s3, {:bucket_name => ENV['S3_BUCKET_NAME'], :access_key_id => ENV['S3_ACCESS_KEY'], :secret_access_key => ENV['S3_SECRET']}   
  
  define_url do |app, job, opts|    
    if dragonfly_job = DragonflyJob.find_by(signature: job.signature)
      app.datastore.url_for(dragonfly_job.uid)
    else
      app.server.url_for(job, :host => ENV['DOMAIN'])
    end
  end

  before_serve do |job, env|
    uid = job.store
    DragonflyJob.create!(uid: uid, signature: job.signature)
  end
  
end