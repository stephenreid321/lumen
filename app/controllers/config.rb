Lumen::App.controllers do
  
  get '/config' do
    site_admins_only!
    if ENV['HEROKU_APP_NAME'] and ENV['VIRTUALMIN_IP']
      Net::SSH.start(ENV['VIRTUALMIN_IP'], ENV['VIRTUALMIN_USERNAME'], :password => ENV['VIRTUALMIN_PASSWORD']) do |ssh|
        result = ''
        ssh.exec!("ls /notify") do |channel, stream, data|
          result << data
        end
        @notification_script = result.include?("#{ENV['HEROKU_APP_NAME']}.php")      
      end
    end
    erb :config
  end
     
  post '/config' do
    site_admins_only!
    heroku = Heroku::API.new
    params[:options].each { |k,v|
      case v
      when 'edit'
        heroku.put_config_vars(ENV['HEROKU_APP_NAME'], k => params[k])
      end
    }
    flash[:notice] = "<strong>Sweet.</strong> Your config vars were updated."
    redirect '/config'
  end  
  
  get '/config/restart' do
    site_admins_only!
    heroku = Heroku::API.new
    heroku.post_ps_restart(ENV['HEROKU_APP_NAME'])
    redirect '/config'
  end
    
  get '/config/create_notification_script' do
    site_admins_only!
    require 'net/scp'
    Net::SSH.start(ENV['VIRTUALMIN_IP'], ENV['VIRTUALMIN_USERNAME'], :password => ENV['VIRTUALMIN_PASSWORD']) do  |ssh|
      ssh.exec!("mkdir /notify")
      ssh.exec!("chmod 777 /notify")
      Net::SCP.start(ENV['VIRTUALMIN_IP'], ENV['VIRTUALMIN_USERNAME'], :password => ENV['VIRTUALMIN_PASSWORD']) do |scp|
        scp.upload! StringIO.new(erb(:'notify/notify.php', :layout => false)), "/notify/#{ENV['HEROKU_APP_NAME']}.php"
        scp.upload! Padrino.root('app','views','notify','PlancakeEmailParser.php'), "/notify"
      end
      ssh.exec!("chmod 777 /notify/*")
    end
    redirect '/config'
  end  
    
end