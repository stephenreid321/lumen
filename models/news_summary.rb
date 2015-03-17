class NewsSummary
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group, index: true
  has_many :daily_digests, :dependent => :destroy

  field :title, :type => String
  field :newsme_username, :type => String  
  field :order, :type => Integer
  
  validates_presence_of :group, :title
    
  def self.admin_fields
    {
      :group_id => :lookup,
      :title => :text,
      :newsme_username => :text,
      :order => :text
    }
  end
  
  def self.date
    Time.now.hour >= (ENV['NEWSME_SWITCH_HOUR'] || 7 ).to_i ? Date.today - 1 : Date.today - 2
  end
  
  after_save :get_current_digest!
  def get_current_digest!
    daily_digests.create :date => Date.yesterday, :body => begin
      Mechanize.new.get("http://www.news.me/#{newsme_username}").search('.top-stories.stories-list').to_s
    rescue
      nil
    end
  end
  
  def top_stories(from,to)
    x = []
    daily_digests.where(:date.gte => from).where(:date.lt => to+1).each { |daily_digest|
      Nokogiri::HTML(daily_digest.body).css('.story-content').each { |story|
        x << {:daily_digest => daily_digest, :story => story}
      }
    }
    x.sort_by! { |e| e[:story].css('.story-tweeters a').length }    
    x.reverse!
    x    
  end
  
end