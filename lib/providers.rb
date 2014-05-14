class Provider
  
  @@all = []
    
  attr_accessor :display_name, :omniauth_name, :icon, :nickname, :profile_url, :image
  
  def initialize(display_name, options={})
    @display_name = display_name
    @omniauth_name = options[:omniauth_name] || display_name.downcase
    @icon = options[:icon] || display_name.downcase
    @nickname = options[:nickname] || ->(hash){ hash['info']['nickname'] }
    @profile_url = options[:profile_url] || ->(hash){ "http://#{hash['provider']}.com/#{hash['info']['nickname']}" }
    @image = options[:image] || ->(hash){ hash['info']['image'] }
    @@all << self
  end
  
  def registered?
    ENV["#{display_name.upcase}_KEY"] && ENV["#{display_name.upcase}_SECRET"]
  end
  
  def self.all
    @@all
  end
  
  def self.registered
    all.select { |provider| provider.registered? }
  end
  
  def self.object(omniauth_name)    
    all.find { |provider| provider.omniauth_name == omniauth_name }
  end    

end

Provider.new('Twitter', image: ->(hash){ hash['info']['image'].gsub(/_normal/,'') })
Provider.new('Facebook', image: ->(hash){ hash['info']['image'].gsub(/square/,'large') })
Provider.new('Google', omniauth_name: 'google_oauth2', icon: 'google-plus', nickname: ->(hash) { hash['info']['name'] }, profile_url: ->(hash){ "http://plus.google.com/#{hash['uid']}"})
Provider.new('LinkedIn', nickname: ->(hash) { hash['info']['name'] }, profile_url: ->(hash){ hash['info']['urls']['public_profile'] })