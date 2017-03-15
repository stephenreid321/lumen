class Opengraph
    
  def self.fetch(url)
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
  