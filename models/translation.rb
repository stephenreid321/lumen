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
      'home' => 'home',
      'my_groups' => 'my groups',
      'all_groups' => 'all groups',
      'edit_profile_and_connect_accounts' => 'edit profile & connect accounts',
      'sign_out' => 'Sign out',
      'sign_in' => 'Sign in',
      'organisation' => 'organisation',
      'organisations' => 'organisations',
      'host_organisation' => 'host organisation',
      'sector' => 'sector',
      'sectors' => 'sectors',
      'position' => 'position',
      'positions' => 'positions',      
      'account_tagship' => 'area of expertise',
      'account_tagships' => 'areas of expertise',
    }
  end
      
end
