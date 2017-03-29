Airbrake.configure do |config|
  config.host = (Config['AIRBRAKE_HOST'] or 'airbrake.io')
  config.project_id = (Config['AIRBRAKE_PROJECT_ID'] or 1)
  config.project_key = (Config['AIRBRAKE_PROJECT_KEY'] or Config['AIRBRAKE_API_KEY'] or 'project_key')
  config.environment = Padrino.env
end

Airbrake.add_filter do |notice|
  if notice[:errors].any? { |error| error[:type] == 'Sinatra::NotFound' }
    notice.ignore!
  end
end  
