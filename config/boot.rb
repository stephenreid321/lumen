# Defines our constants
RACK_ENV = ENV['RACK_ENV'] ||= 'development'  unless defined?(RACK_ENV)
PADRINO_ROOT = File.expand_path('../..', __FILE__) unless defined?(PADRINO_ROOT)

# Load our dependencies
require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

require 'net/imap'

Padrino.load!

Dragonfly.app.configure do    
  plugin :imagemagick
  url_format '/media/:job/:name'    
  datastore :s3, {:bucket_name => ENV['S3_BUCKET_NAME'], :access_key_id => ENV['S3_ACCESS_KEY'], :secret_access_key => ENV['S3_SECRET'], :region => ENV['S3_REGION']}
  secret ENV['DRAGONFLY_SECRET']
  
  define_url do |app, job, opts|    
    app.datastore.url_for((DragonflyJob.find_by(signature: job.signature) || DragonflyJob.create(uid: job.store, signature: job.signature)).uid)
  end
end

Delayed::Worker.max_attempts = 1
Delayed::Worker.destroy_failed_jobs = false

I18n.enforce_available_locales = false

Mongoid.load!("#{PADRINO_ROOT}/config/mongoid.yml")
Mongoid.raise_not_found_error = false
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO