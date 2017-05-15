Config.each { |config|
  if ENV[config.slug] and ENV[config.slug] != config.body
    config.destroy
  end
}