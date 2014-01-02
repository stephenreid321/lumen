class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  field :name, :type => String
  field :email, :type => String
  field :secret_token, :type => String
  field :crypted_password, :type => String
  field :role, :type => String, :default => 'user'
  field :time_zone, :type => String, :default => 'London'  
  field :affiliated, :type => Boolean
  field :has_picture, :type => Boolean
  field :picture_uid  
  field :phone, :type => String 
  field :location, :type => String 
  field :expertise, :type => String    
    
  has_many :sign_ins, :dependent => :destroy  
  has_many :page_views, :dependent => :destroy  
  has_many :memberships, :dependent => :destroy    
  has_many :conversation_posts, :dependent => :destroy
  has_many :events_as_creator, :class_name => 'Event', :inverse_of => :account, :dependent => :destroy
        
  has_many :affiliations, :dependent => :destroy
  accepts_nested_attributes_for :affiliations, allow_destroy: true, reject_if: :all_blank

  def network    
    Account.where(:id.in => memberships.map(&:group).map(&:memberships).flatten.map(&:account_id))
  end
  
  def events
    Event.where(:id.in => memberships.map(&:group).map(&:events).flatten.map(&:id))
  end  
  
  def conversations
    Conversation.where(:id.in => memberships.map(&:group).map(&:conversations).flatten.map(&:_id))
  end
  
  def news_summaries
    NewsSummary.where(:id.in => memberships.map(&:group).map(&:news_summaries).flatten.map(&:_id))
  end
  
  def expertises
    expertise ? expertise.split(',').map { |x| x.split(';') }.flatten.map(&:downcase).map(&:strip) : []
  end
           
  # Picture
  dragonfly_accessor :picture, :app => :pictures do
    after_assign :resize_picture
  end
  def resize_picture
    picture.thumb('500x500>')
  end 
  attr_accessor :rotate_picture_by
  before_validation :rotate_picture
  def rotate_picture
    if self.picture and self.rotate_picture_by
      picture.rotate(self.rotate_picture_by)
    end  
  end
  
  # Connections  
  has_many :connections, :dependent => :destroy
  accepts_nested_attributes_for :connections
  def self.providers
    [
      Provider.new('Twitter', image: ->(hash){ hash['info']['image'].gsub(/_normal/,'') }),
      Provider.new('Facebook', image: ->(hash){ hash['info']['image'].gsub(/square/,'large') }),
      Provider.new('Google', omniauth_name: 'google_oauth2', icon: 'google-plus', nickname: ->(hash) { hash['info']['name'] }, profile_url: ->(hash){ "http://plus.google.com/#{hash['uid']}"}),
      Provider.new('LinkedIn', nickname: ->(hash) { hash['info']['name'] }, profile_url: ->(hash){ hash['info']['urls']['public_profile'] })
    ]
  end  
  def self.provider_object(omniauth_name)    
    providers.find { |provider| provider.omniauth_name == omniauth_name }
  end  
                       
  attr_accessor :password, :password_confirmation 

  validates_presence_of :name, :email
  validates_presence_of :password, :if => :password_required
  validates_presence_of :password_confirmation, :if => :password_required  
  validates_presence_of :role, :time_zone # defaults
  
  validates_length_of :email, :within => 3..100
  validates_uniqueness_of :email, :case_sensitive => false
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i  
  validates_length_of :password, :within => 4..40, :if => :password_required
  validates_confirmation_of :password, :if => :password_required 
    
  before_validation :set_has_picture
  def set_has_picture
    self.has_picture = (self.picture ? true : false)
  end
    
  def generate_secret_token
    update_attribute(:secret_token, ::BCrypt::Password.create(self.id)) if !self.secret_token
    self.secret_token
  end  
  
  def update_affiliated!
    update_attribute(:affiliated, affiliations.count > 0)
  end  
      
  def self.fields_for_index
    [:name, :email, :phone, :created_at]
  end
    
  def self.fields_for_form
    {
      :name => :text,
      :email => :text,
      :secret_token => :text,
      :phone => :text,      
      :picture => :image,
      :role => :select,
      :time_zone => :select,
      :password => :password,
      :password_confirmation => :password,
      :location => :text,
      :expertise => :text,
      :affiliated => :check_box,
      :affiliations => :collection
    }
  end
  
  def self.filter_options
    {
      :o => 'created_at',
      :d => 'desc'
    }    
  end
    
  def self.edit_hints
    {
      :password => 'Leave blank to keep existing password'      
    }
  end   
           
  def self.time_zones
    ['']+ActiveSupport::TimeZone::MAPPING.keys.sort
  end  
  
  def self.roles
    ['user','admin']
  end    
  
  def admin?
    role == 'admin'
  end
  
  def self.lookup
    :name
  end  
    
  def uid
    id
  end
  
  def info
    {:email => email, :name => name}
  end
  
  def self.authenticate(email, password)
    account = find_by(email: /^#{Regexp.escape(email)}$/i) if email.present?
    account && account.has_password?(password) ? account : nil
  end
  
  before_save :encrypt_password, :if => :password_required

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end
  
  def self.generate_password(len)
    chars = ("a".."z").to_a + ("0".."9").to_a
    return Array.new(len) { chars[rand(chars.size)] }.join
  end 

  private
  def encrypt_password
    self.crypted_password = ::BCrypt::Password.create(self.password)
  end

  def password_required
    crypted_password.blank? || self.password.present?
  end  
    
end
