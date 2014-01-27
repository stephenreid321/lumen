Lumen::App.controller do
  
  get '/update_news' do
    site_admins_only!
    NewsSummary.each { |news_summary| news_summary.get_current_digest! }
  end
    
  get '/send_digests' do
    site_admins_only!
    Group.each { |group|        
      group.memberships.where(:notification_level.in => ['daily','weekly']).each { |membership|
        
        case membership.notification_level
        when 'daily'
          title = "Digest for #{group.slug}"
          from = 1.day.ago.to_date
          to = Date.today
        when 'weekly'
          title = "Digest for #{group.slug}"
          from = 1.week.ago.to_date
          to = Date.today
        end         

        Mail.defaults do
          delivery_method :smtp, { :address => group.smtp_server, :port => group.smtp_port, :authentication => group.smtp_authentication, :enable_ssl => group.smtp_ssl, :user_name => group.smtp_username, :password => group.smtp_password }
        end    
                                
        mail = Mail.new
        mail.to = membership.account.email
        mail.from = "#{group.smtp_name} <#{group.smtp_address}>"
        mail.subject = "#{title}: #{compact_daterange(Date.parse(from),Date.parse(to))}"
        mail.html_part do
          content_type 'text/html; charset=UTF-8'
          body Mechanize.new.get("http://#{ENV['DOMAIN']}/groups/#{group.slug}/digest?email=true&title=#{title}&from=#{from.to_s(:db)}&to=#{to.to_s(:db)}&token=#{membership.account.generate_secret_token}").content
        end
        mail.deliver!                      
    
      }        
    }
  end
    
end