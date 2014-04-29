class WallPost
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model
   
  field :body, :type => String  
  field :title, :type => String
  field :url, :type => String
  field :description, :type => String  
  field :picture, :type => String
  field :player, :type => String
  
  field :file_uid, :type => String
  field :file_name, :type => String  
  dragonfly_accessor :file, :app => :files
  
  validates_presence_of :body, :account, :group
  
  belongs_to :account, index: true
  belongs_to :group, index: true
      
  def self.fields_for_index
    [:body, :account_id, :group_id]
  end
  
  def self.fields_for_form
    {
      :body => :wysiwyg,
      :title => :text,
      :url => :text,
      :description => :text_area,
      :picture => :text,
      :player => :text
    }
  end

  def self.opengraph(url)
    agent = Mechanize.new
    og = {}
    url = url.gsub('feature=player_embedded&','')
    begin
      page = agent.get("http://iframely.com/iframely?uri=#{URI.escape(url)}").body
    rescue
      return og
    end
    j = JSON.parse(page)
    og[:url] = url
    if j['meta']
      og[:title] = j['meta']['title'] 
      if j['meta']['description']
        og[:description] = j['meta']['description'].split(' ')[0..49].join(' ')
      end
    end    
    if j['links']
      if (pic = j['links'].find { |x| x['rel'].include?('og') or x['rel'].include?('thumbnail') })
        og[:picture] = pic['href']
      end
      if (player = j['links'].find { |x| x['rel'].include?('player') })
        og[:player] = player['href']
      end      
    end
    og
  end   
    
end
