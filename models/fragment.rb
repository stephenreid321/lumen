class Fragment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :slug, :type => String  
  field :body, :type => String  
  field :page, :type => Boolean
  field :public, :type => Boolean
  
  validates_presence_of :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
    
  def self.admin_fields
    {
      :title => :text,
      :slug => :slug,
      :body => :wysiwyg,
      :page => :check_box,
      :public => :check_box
    }
  end
    
end
