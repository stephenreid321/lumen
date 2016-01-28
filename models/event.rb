class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group, index: true
  belongs_to :account, index: true
  belongs_to :organisation, index: true

  field :name, :type => String
  field :start_time, :type => ActiveSupport::TimeWithZone
  field :end_time, :type => ActiveSupport::TimeWithZone
  field :consider_time, :type => Boolean
  field :location, :type => String
  field :coordinates, :type => Array
  field :details, :type => String
  field :reason, :type => String
  field :ticketing, :type => String
  field :tickets_link, :type => String
  field :more_info, :type => String
  field :publicity_tweet, :type => String
  
  include Geocoder::Model::Mongoid
  geocoded_by :location
  def lat; coordinates[1] if coordinates; end  
  def lng; coordinates[0] if coordinates; end  
  after_validation do
    self.geocode || (self.coordinates = nil)
  end  
  
  def self.marker_color
    '3DA2E4'
  end  
    
  attr_accessor :start_conversation
  
  validates_presence_of :name, :start_time, :end_time, :group, :account, :ticketing
  
  before_validation :ensure_end_after_start
  def ensure_end_after_start
    errors.add(:end_time, 'must be after the start time') unless end_time >= start_time
  end
  
  before_validation do
    self.more_info = "http://#{self.more_info}" if self.more_info and !(self.more_info =~ /\Ahttps?:\/\//)
  end  
    
  def self.admin_fields
    {
      :name => :text,
      :start_time => :datetime,
      :end_time => :datetime,
      :consider_time => :check_box,
      :location => :text,
      :coordinates => :geopicker,              
      :details => :text_area,
      :more_info => :text,
      :reason => :text,
      :publicity_tweet => :text,
      :ticketing => :select,
      :tickets_link => :text,
      :group_id => :lookup,
      :account_id => :lookup,
      :organisation_id => :lookup
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :name => 'Event name',
      :organisation_id => I18n.t(:host_organisation).capitalize,
      :start_time => 'From',
      :end_time => 'To',
      :location => 'Where',
      :more_info => 'Link to full event details',
      :reason => 'Members of this group should come because… (optional)',
      :publicity_tweet => 'What should people tweet to publicise this event?',
      :start_conversation => 'Send an email notification to all group members about the addition of this event (use with care)'
    }[attr.to_sym] || super  
  end    
  
  def self.ticketings
    ['No ticket required','Free, but please RSVP', 'Ticket required']
  end
    
  def when_details
    if consider_time
      if start_time.to_date == end_time.to_date
        "#{start_time.to_date.to_s(:no_year)}, #{start_time.to_s(:no_double_zeros)} &ndash; #{end_time.to_s(:no_double_zeros)}"
      else
        "#{start_time.to_date.to_s(:no_year)}, #{start_time.to_s(:no_double_zeros)} &ndash; #{end_time.to_date.to_s(:no_year)}, #{end_time.to_s(:no_double_zeros)}"
      end
    else
      if start_time.to_date == end_time.to_date
        start_time.to_date.to_s(:no_year)
      else
        "#{start_time.to_date.to_s(:no_year)} &ndash; #{end_time.to_date.to_s(:no_year)}"
      end
    end
  end
  
  def self.ical(eventable)
    cal = RiCal.Calendar do |rcal|
      rcal.add_x_property('X-WR-CALNAME', eventable.is_a?(Group) ? eventable.email : ENV['DOMAIN'])
      eventable.events.each { |event|
        rcal.event do |revent|
          revent.summary = event.name
          revent.dtstart =  event.consider_time ? event.start_time : event.start_time.to_date
          revent.dtend = event.consider_time ? event.end_time : (event.end_time.to_date + 1.day)
          (revent.location = event.location) if event.location
          revent.description = "http://#{ENV['DOMAIN']}/groups/#{event.group.slug}/events/#{event.id}"
        end
      }
    end
    cal.export
  end
  
  def self.future
    self.where(:start_time.gte => Date.today).order_by(:start_time.asc)
  end
  
  def self.json(eventable, period_start, period_end)
    events = eventable.events
    events = events.where(:start_time.lte => Time.zone.parse(period_end))
    events = events.where(:end_time.gte => Time.zone.parse(period_start))
    JSON.pretty_generate events.map { |event| 
      {
        :title => event.name,
        :start => event.start_time.iso8601,
        :end => event.end_time.iso8601, 
        :allDay => !event.consider_time,
        :when_details => event.when_details,
        :location => event.location,
        :reason => event.reason,
        :more_info => event.more_info,
        :ticketing => event.ticketing,
        :tickets_link => event.tickets_link,
        :account_id => event.account_id.to_s,
        :account_name => event.account.name,
        :organisation_id => event.organisation_id.to_s,
        :organisation_name => event.organisation.try(:name),        
        :id => event.id.to_s,
        :className => "event-#{event.id}",
        :group_slug => event.group.slug,
        :eventable => eventable.class.to_s
      }
    }    
  end
  
end
