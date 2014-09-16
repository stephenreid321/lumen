class Translation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :key, :type => String
  field :value, :type => String  
  
  index({key: 1 }, {unique: true})
  
  belongs_to :language
  
  validates_presence_of :key, :value, :language
  validates_uniqueness_of :key, :scope => :language
    
  def self.fields_for_index
    [:language_id, :key, :value]
  end
  
  def self.fields_for_form
    {
      :language_id => :lookup,
      :key => :text,
      :value => :text
    }
  end
  
  def self.lookup
    :summary
  end
  
  def summary
    "#{key}: #{value}"
  end
    
  def self.defaults
    {
      :home => 'home',
      :my_groups => 'my groups',
      :all_groups => 'all groups',
      :edit_profile_and_connect_accounts => 'edit profile & connect accounts',
      :sign_out => 'sign out',
      :sign_in => 'sign in',
      :organisation => 'organisation',
      :organisations => 'organisations',
      :host_organisation => 'host organisation',
      :sector => 'sector',
      :sectors => 'sectors',
      :position => 'position',
      :positions => 'positions',      
      :account_tagship => 'area of expertise',
      :account_tagships => 'areas of expertise',
      :news => 'news',
      :digest => 'digest',
      :map => 'map',
      :wall => 'wall',
      :docs => 'docs',
      :surveys => 'surveys',
      :calendar => 'calendar',
      :conversations => 'conversations',
      :'members_in_this_group.one' => '1 member in this group',
      :'members_in_this_group.other' => '%{count} members in this group',
      :'people_in_your_groups.one' => '1 person in your groups',
      :'people_in_your_groups.other' => '%{count} people in your groups'
    }
  end
      
end
