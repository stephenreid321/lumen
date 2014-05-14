class Fragment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String
  field :body, :type => String  
  
  index({slug: 1 }, {unique: true})
  
  validates_presence_of :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
    
  def self.fields_for_index
    [:slug, :body]
  end
  
  def self.fields_for_form
    {
      :slug => :text,
      :body => :wysiwyg
    }
  end
  
  def self.filter_options
    {
      :o => :slug,
      :d => :asc
    }
  end
    
end
