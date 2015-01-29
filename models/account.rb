class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
    
  field :name, :type => String
  field :email, :type => String
  field :secret_token, :type => String
  field :crypted_password, :type => String
  field :admin, :type => Boolean
  field :time_zone, :type => String
  field :has_picture, :type => Boolean
  field :picture_uid, :type => String  
  field :phone, :type => String 
  field :website, :type => String 
  field :location, :type => String 
  field :coordinates, :type => Array 
  field :translator, :type => Boolean
    
  EnvFields.set(self)
  
  include Geocoder::Model::Mongoid
  geocoded_by :location  
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.geocode || (self.coordinates = nil)
  end

  has_many :sign_ins, :dependent => :destroy  
  has_many :page_views, :dependent => :destroy  
  has_many :memberships, :class_name => "Membership", :inverse_of => :account, :dependent => :destroy
  has_many :memberships_added, :class_name => "Membership", :inverse_of => :added_by, :dependent => :nullify
  has_many :membership_requests, :dependent => :destroy  
  has_many :conversation_mutes, :dependent => :destroy
  has_many :conversation_post_read_receipts, :dependent => :destroy
  has_many :conversation_post_bcc_recipients, :dependent => :destroy
  has_many :conversations_as_creator, :class_name => 'Conversation', :dependent => :destroy
  has_many :conversation_posts_as_creator, :class_name => 'ConversationPost', :dependent => :destroy
  has_many :events_as_creator, :class_name => 'Event', :inverse_of => :account, :dependent => :destroy
  has_many :wall_posts_as_creator, :class_name => 'WallPost', :inverse_of => :account, :dependent => :destroy
  has_many :spaces_as_creator, :class_name => 'Space', :inverse_of => :account, :dependent => :destroy
  has_many :docs_as_creator, :class_name => 'Doc', :inverse_of => :account, :dependent => :destroy
  has_many :surveys_as_creator, :class_name => 'Survey', :inverse_of => :account, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :plus_ones, :dependent => :destroy
  
  belongs_to :language, index: true
  
  has_many :affiliations, :dependent => :destroy
  accepts_nested_attributes_for :affiliations, allow_destroy: true, reject_if: :all_blank
  
  has_many :account_tagships, :dependent => :destroy
  accepts_nested_attributes_for :account_tagships, allow_destroy: true, reject_if: :all_blank
    
  attr_accessor :account_tag_ids
  before_validation :create_account_tags
  def create_account_tags
    if @account_tag_ids
      current_account_tag_ids = account_tagships.map(&:account_tag_id).map(&:to_s)
      tags_to_remove = current_account_tag_ids - @account_tag_ids
      tags_to_add = @account_tag_ids - current_account_tag_ids
      tags_to_remove.each { |account_tag_id| account_tagships.find_by(account_tag_id: account_tag_id).destroy }
      tags_to_add.each { |account_tag_id| account_tagships.create(account_tag_id: account_tag_id) }
    end
  end  
  
  attr_accessor :group_ids
  before_validation :join_groups_via_profile
  def join_groups_via_profile
    if @group_ids
      current_group_ids = memberships.map(&:group).select { |group| group.group_type.try(:join_groups_via_profile) }.map(&:id).map(&:to_s)
      groups_to_leave = current_group_ids - @group_ids
      groups_to_join = @group_ids - current_group_ids
      groups_to_leave.each { |group_id| memberships.find_by(group_id: group_id).try(:destroy) }
      groups_to_join.each { |group_id| memberships.create(:group_id => group_id) }
    end
  end  
  
  def self.marker_color
    '3DA2E4'
  end
    
  def public_memberships
    Membership.where(:id.in => memberships.select { |membership| !membership.group.secret? }.map(&:_id))
  end  
          
  def network    
    Account.where(:id.in => memberships.map(&:group).map { |group| group.memberships.only(:account_id).where(:status => 'confirmed') }.flatten.map(&:account_id))
  end
  
  def network_organisations
    Organisation.where(:id.in => Affiliation.where(:account_id.in => network.only(:id).map(&:id)).only(:organisation_id).map(&:organisation_id))
  end
  
  def network_sectors
    Sector.where(:id.in => Sectorship.where(:organisation_id.in => network_organisations.only(:id).map(&:id)).only(:sector_id).map(&:sector_id))
  end
    
  def events
    Event.where(:group_id.in => memberships.map(&:group_id))
  end  
  
  def conversations
    Conversation.where(:group_id.in => memberships.map(&:group_id))
  end
  
  def conversation_posts
    ConversationPost.where(:group_id.in => memberships.map(&:group_id))
  end
  
  def spaces
    Space.where(:group_id.in => memberships.map(&:group_id))
  end  
  
  def news_summaries
    NewsSummary.where(:group_id.in => memberships.map(&:group_id))
  end
    
  def wall_posts
    WallPost.where(:group_id.in => memberships.map(&:group_id))
  end  
  
  def docs
    Doc.where(:group_id.in => memberships.map(&:group_id))
  end 
  
  def surveys
    Survey.where(:group_id.in => memberships.map(&:group_id))
  end   
              
  # Picture
  dragonfly_accessor :picture do
    after_assign { |picture| self.picture = picture.thumb('500x500>') }
  end
  attr_accessor :rotate_picture_by
  before_validation :rotate_picture
  def rotate_picture
    if self.picture and self.rotate_picture_by
      picture.rotate(self.rotate_picture_by)
    end
    return true
  end
    
  # Provider links  
  has_many :provider_links, :dependent => :destroy
  accepts_nested_attributes_for :provider_links
                        
  attr_accessor :password, :password_confirmation 
  
  before_validation :check_for_affiliations
  def check_for_affiliations    
    errors.add(:affiliations, 'must be present') if self.persisted? and ENV['REQUIRE_ACCOUNT_AFFILIATIONS'] and self.affiliations.empty?
  end  

  validates_presence_of :name, :email
  validates_presence_of :location, :if => -> { self.persisted? and ENV['REQUIRE_ACCOUNT_LOCATION'] }
  validates_presence_of :password, :if => :password_required
  validates_presence_of :password_confirmation, :if => :password_required  
  
  validates_length_of :email, :within => 3..100
  validates_uniqueness_of :email, :case_sensitive => false
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i  
  validates_length_of :password, :within => 4..40, :if => :password_required
  validates_confirmation_of :password, :if => :password_required 
  
  index({email: 1 }, {unique: true})
  
  before_validation do
    self.website = "http://#{self.website}" if self.website and !(self.website =~ /\Ahttps?:\/\//)
  end  
    
  before_validation :set_has_picture
  def set_has_picture
    self.has_picture = (self.picture ? true : false)
    return true
  end
    
  def generate_secret_token
    update_attribute(:secret_token, ::BCrypt::Password.create(self.id)) if !self.secret_token
    self.secret_token
  end  
  
  def self.new_tips
    {
      :location => 'Your home location, to appear on maps'
    }
  end
  
  def self.edit_tips
    self.new_tips
  end  
              
  def self.admin_fields
    {
      :name => :text,
      :email => :text,
      :secret_token => :text,
      :phone => :text, 
      :website => :text,
      :picture => :image,
      :admin => :check_box,
      :translator => :check_box,
      :time_zone => :select,
      :language_id => :lookup,
      :password => :password,
      :password_confirmation => :password,
      :location => :text,
      :affiliations => :collection
    }.merge(EnvFields.fields(self))
  end
    
  def self.edit_hints
    {
      :password => 'Leave blank to keep existing password'      
    }
  end   
  
  def self.human_attribute_name(attr, options={})  
    {
      :account_tag_ids => I18n.t(:account_tagships).capitalize,
      :expertise => 'Areas of expertise',
      :password_confirmation => "Password again"
    }[attr.to_sym] || super  
  end     
           
  def self.time_zones
    ['']+ActiveSupport::TimeZone::MAPPING.keys.sort
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
