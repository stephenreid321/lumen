class FeedPost
  include Mongoid::Document
  include Mongoid::Timestamps
   
  field :body, :type => String  
  field :link, :type => String
  field :title, :type => String
  field :url, :type => String
  field :description, :type => String  
  field :picture, :type => String
  
  belongs_to :account, index: true
  belongs_to :group, index: true
      
  def self.fields_for_index
    [:body, :link]
  end
  
  def self.fields_for_form
    {
      :body => :wysiwyg,
      :link => :text,
      :title => :text,
      :url => :text,
      :description => :text_area,
      :picture => :text
    }
  end

  def self.opengraph(url)
    agent = Mechanize.new
    result = agent.get('http://developers.facebook.com/tools/debug/og/object?q='+url.to_s)
    og = {}
    [:title, :url, :description].each { |k|
      begin
        og[k] = result.search("//div[@id='object_properties']//th[contains(text(),\"og:#{k}\")]").first.next.text
      rescue
        nil
      end
    }
    begin
      og[:picture] = result.search("//div[@id='object_properties']//th[contains(text(),\"og:image\")]").first.next.search('img').first['src']
    rescue
      nil
    end
    og
  end   
    
end
