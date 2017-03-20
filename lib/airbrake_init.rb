Airbrake.configure do |config|
  config.host = ENV['AIRBRAKE_HOST']
  config.project_id = (ENV['AIRBRAKE_PROJECT_ID'] or 1)
  config.project_key = (ENV['AIRBRAKE_PROJECT_KEY'] or ENV['AIRBRAKE_API_KEY'] or 'project_key')
  config.environment = Padrino.env
end

Airbrake.add_filter do |notice|
  if notice[:errors].any? { |error| error[:type] == 'Sinatra::NotFound' }
    notice.ignore!
  end
end  
