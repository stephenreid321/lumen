class NewsSummary
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group
  has_many :daily_digests, :dependent => :destroy

  field :title, :type => String
  field :newsme_username, :type => String  
  
  validates_presence_of :group, :title
    
  def self.fields_for_index
    [:group_id, :title, :newsme_username]
  end
  
  def self.lookup
    :id
  end
  
  def self.fields_for_form
    {
      :group_id => :lookup,
      :title => :text,
      :newsme_username => :text
    }
  end
  
  after_save :get_current_digest!
  def get_current_digest!
    daily_digests.create! :date => Date.yesterday, :body => begin
      Mechanize.new.get("http://www.news.me/#{newsme_username}").search('.top-stories.stories-list').to_s
    rescue
      nil
    end
  end
  
end