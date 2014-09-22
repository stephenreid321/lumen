class DailyDigest
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :news_summary, index: true

  field :body, :type => String  
  field :date, :type => Date
  
  validates_presence_of :body, :date
  validates_uniqueness_of :date, :scope => :news_summary
    
  def self.admin_fields
    {
      :news_summary_id => :lookup,
      :body => :text_area,
      :date => :text
    }
  end
    
end