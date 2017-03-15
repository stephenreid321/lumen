Airbrake.configure do |config|
  config.api_key = Config['AIRBRAKE_API_KEY']  
  config.host = Config['AIRBRAKE_HOST'] if Config['AIRBRAKE_HOST']
  config.ignore << "Sinatra::NotFound"
end