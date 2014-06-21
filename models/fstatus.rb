class Fstatus
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
  
  field :message, :type => String
  field :link, :type => String
  field :photo_uid, :type => String   
  field :post_at, :type => Time
  field :attempted_at, :type => Time    
      
  belongs_to :account
  
  dragonfly_accessor :photo    
  
  validates_presence_of :account         
  validates_presence_of :post_at, :unless => :post_now  
  validate :post_at_must_be_in_the_future, :unless => :post_now
  def post_at_must_be_in_the_future
    errors.add(:post_at, "must be in the future") unless post_at > Time.now + 10.seconds
  end  
  validate :either_link_or_photo
  def either_link_or_photo
    errors.add(:photo, "cannot be present as well as a link") if photo and link
  end
     
  attr_accessor :post_now  
  after_save do    
    post_now ? deliver_now : deliver_later
  end
           
  def deliver_now
    if !attempted_at? 
      update_attribute(:attempted_at, Time.now)
      if link
        post = api.put_object('me', 'feed',
          :message => message,
          :link => link
        ) 
      elsif photo
        post = api.put_object('me', 'photos',
          :message => message,
          :url => photo.remote_url
        )         
      else
        post = api.put_object('me', 'feed',
          :message => message
        )           
      end
    end
  end

  def deliver_later    
    deliver_now if Time.now >= post_at and Time.now < post_at + 15.minutes
  end
  handle_asynchronously :deliver_later, :run_at => Proc.new { |fstatus| fstatus.post_at }     
  
  def api
    Koala::Facebook::API.new(account.connections.find_by(provider: 'Facebook').access_token)
  end
      
  def self.fields_for_index
    [:account_id, :message, :link, :photo_uid, :created_at, :post_at, :attempted_at]
  end
  
  def self.fields_for_form
    {
      :message => :text_area,
      :link => :text,
      :photo => :file,      
      :post_now => :check_box,
      :post_at => :datetime,
      :account_id => :lookup
    } 
  end  

  def self.filter_options
    {o: 'created_at', d: 'desc'}
  end    
  
end  
