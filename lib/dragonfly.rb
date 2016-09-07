Dragonfly.app.configure do    
  plugin :imagemagick
  url_format '/media/:job/:name'    
  
  if Config['S3_BUCKET_NAME']
    datastore :s3, {:bucket_name => Config['S3_BUCKET_NAME'], :access_key_id => Config['S3_ACCESS_KEY'], :secret_access_key => Config['S3_SECRET'], :region => Config['S3_REGION'], :url_scheme => (Config['SSL'] ? 'https' : 'http')}
  else
    `ln -s /storage #{PADRINO_ROOT}/assets/dragonfly`
    datastore :file, {:root_path => "#{PADRINO_ROOT}/assets/dragonfly", :server_root => 'dragonfly'}
  end
  
  secret Config['DRAGONFLY_SECRET']
  
  define_url do |app, job, opts|    
    app.datastore.url_for((DragonflyJob.find_by(signature: job.signature) || DragonflyJob.create(uid: job.store, signature: job.signature)).uid)
  end
end