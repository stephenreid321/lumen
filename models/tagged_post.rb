class TaggedPost
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
  dragonfly_accessor :file
  
  validates_presence_of :body, :account
  
  belongs_to :account, index: true
  
  has_many :tagged_post_tagships, :dependent => :destroy
  
  has_many :tagged_post_tagships, :dependent => :destroy
  accepts_nested_attributes_for :tagged_post_tagships, allow_destroy: true, reject_if: :all_blank  
      
  def self.fields_for_index
    [:body, :account_id]
  end
  
  def self.fields_for_form
    {
      :body => :wysiwyg,
      :title => :text,
      :url => :text,
      :description => :text_area,
      :picture => :text,
      :player => :text,
      :tagged_post_tagships => :collection
    }
  end
  
  def self.lookup
    :id
  end
    
end
