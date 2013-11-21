Padrino.configure_apps do
  set :session_secret, '278393b81379df7a348b399d004cfa8147999c5b75470b1946b4217724867722'     
end

Padrino.mount('ActivateApp::App', :app_file => Padrino.root('app/app.rb')).to('/')
Padrino.mount('ActivateAdmin::App', :app_file => ActivateAdmin.root('app/app.rb')).to('/admin')
