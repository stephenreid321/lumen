Config.each { |config|
  if ENV[config.slug] and ENV[config.slug] != config.body
    raise "ENV['#{config.slug}'] != config.body"
  end
}