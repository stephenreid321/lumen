if Padrino.env == :production
  Mail::Logger.configure do |config|
    config.log_path = "../log"
    config.log_file_name = "production.log"
  end
end