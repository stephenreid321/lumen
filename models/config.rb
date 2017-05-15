class Config
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String  
  field :body, :type => String  
  
  validates_presence_of :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[A-Z0-9\_]+\z/
    
  def self.admin_fields
    {
      :slug => :slug,
      :body => :text
    }
  end
  
  def self.[](slug)
    ENV[slug] || find_by(slug: slug).try(:body)
  end
    
end
