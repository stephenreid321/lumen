class GroupType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :slug, :type => String
  field :icon, :type => String
  field :description, :type => String
  field :join_groups_via_profile, :type => Boolean
  
  index({slug: 1 }, {unique: true})
  
  has_many :groups, :dependent => :nullify
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :name, :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
  
  before_validation :join_groups_via_profile_to_boolean
  def join_groups_via_profile_to_boolean
    if self.join_groups_via_profile == '0'; self.join_groups_via_profile = false; elsif self.join_groups_via_profile == '1'; self.join_groups_via_profile = true; end; return true
  end    
    
  def self.fields_for_index
    [:name, :slug, :icon, :description, :join_groups_via_profile]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :slug => :slug,
      :icon => :text,
      :description => :text_area,
      :join_groups_via_profile => :check_box,
      :groups => :collection
    }
  end
  
  def self.lookup
    :name
  end
      
end
