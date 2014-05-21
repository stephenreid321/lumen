class Fragment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String
  field :body, :type => String  
  field :page, :type => Boolean
  
  validates_presence_of :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  before_validation :page_to_boolean
  def page_to_boolean
    if self.page == '1'; self.page = true; elsif self.page == '0'; self.page = false; end; return true
  end
    
  def self.fields_for_index
    [:slug, :body, :page]
  end
  
  def self.fields_for_form
    {
      :slug => :text,
      :body => :wysiwyg,
      :page => :check_box
    }
  end
    
end
