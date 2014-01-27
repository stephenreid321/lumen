class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group
  belongs_to :account
  belongs_to :organisation

  field :name, :type => String
  field :start_time, :type => ActiveSupport::TimeWithZone
  field :end_time, :type => ActiveSupport::TimeWithZone
  field :consider_time, :type => Boolean
  field :location, :type => String
  field :details, :type => String
  field :reason, :type => String
  field :ticketing, :type => String
  field :tickets_link, :type => String
  field :more_info, :type => String
  field :publicity_tweet, :type => String
  
  attr_accessor :start_conversation
  
  validates_presence_of :name, :start_time, :end_time, :group, :account, :ticketing
  
  before_validation :ensure_end_after_start
  def ensure_end_after_start
    errors.add(:end_time, 'must be after the start time') unless end_time >= start_time
  end
    
  def self.fields_for_index
    [:name, :start_time, :end_time, :consider_time, :location, :details, :reason, :more_info, :ticketing, :tickets_link, :group_id, :account_id, :organisation_id]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :start_time => :datetime,
      :end_time => :datetime,
      :consider_time => :check_box,
      :location => :text,
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
  
  def self.ticketings
    ['No ticket required','Free, but please RSVP', 'Ticket required']
  end
  
  before_validation :consider_time_to_boolean
  def consider_time_to_boolean
    if self.consider_time == '0'
      self.consider_time = false
    elsif self.consider_time == '1'
      self.consider_time = true
    end
    return true
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
      rcal.add_x_property('X-WR-CALNAME', eventable.is_a?(Group) ? eventable.imap_address : ENV['DOMAIN'])
      eventable.events.each { |event|
        rcal.event do |revent|
          revent.summary = event.name
          revent.dtstart =  event.consider_time ? event.start_time : event.start_time.to_date
          revent.dtend = event.consider_time ? event.end_time : (event.end_time.to_date + 1.day)
          (revent.location = event.location) if event.location
          revent.description = "http://#{ENV['DOMAIN']}/groups/#{event.group.slug}/calendar/#{event.id}"
        end
      }
    end
    cal.export
  end
  
  def self.json(eventable, start_time=nil, end_time=nil)
    events = eventable.events
    events = events.where(:start_time.gte => Time.zone.at(start_time.to_i)) if start_time
    events = events.where(:end_time.lte => Time.zone.at(end_time.to_i)) if end_time
    JSON.pretty_generate events.map { |event| 
      {
        :title => event.name,
        :start => event.start_time.to_s(:db),
        :end => event.end_time.to_s(:db), 
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
