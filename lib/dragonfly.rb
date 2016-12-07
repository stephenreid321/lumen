Dragonfly.app.configure do    
  plugin :imagemagick
  url_format '/media/:job/:name'    
  secret Config['DRAGONFLY_SECRET']
  
  `ln -s /storage #{Padrino.root('app', 'assets', 'dragonfly')}` if Padrino.env == :production
  datastore :file, {:root_path => Padrino.root('app', 'assets', 'dragonfly'), :server_root => 'assets'}
     
  define_url do |app, job, opts|    
    app.datastore.url_for((DragonflyJob.find_by(signature: job.signature) || DragonflyJob.create(uid: job.store, signature: job.signature)).uid)
  end
end