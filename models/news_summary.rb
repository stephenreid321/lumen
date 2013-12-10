class NewsSummary
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :group

  field :title, :type => String
  field :newsme_username, :type => String
  field :body, :type => String  
  field :order, :type => Integer
  
  validates_presence_of :group, :title, :body
    
  def self.fields_for_index
    [:group_id, :title, :newsme_username, :body, :order]
  end
  
  def self.fields_for_form
    {
      :group_id => :lookup,
      :title => :text,
      :newsme_username => :text,
      :body => :text_area,      
      :order => :text   
    }
  end
  
  before_validation :set_body  
  def set_body    
    self.body = begin
      Mechanize.new.get("http://www.news.me/#{self.newsme_username}").search('.top-stories.stories-list').to_s
    rescue
      nil
    end
  end
  
  def fetch!
    set_body; save
  end
  
end