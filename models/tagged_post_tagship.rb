class TaggedPostTagship
  include Mongoid::Document
  include Mongoid::Timestamps
    
  belongs_to :tagged_post, index: true  
  belongs_to :account_tag, index: true
  
  attr_accessor :account_tag_name
  before_validation :find_or_create_account_tag
  def find_or_create_account_tag
    if account_tag_name
      created_account_tag = AccountTag.find_or_create_by(name: self.account_tag_name)
      if created_account_tag.persisted?
        self.account_tag = created_account_tag
      end
    end
  end  
        
  validates_presence_of :tagged_post, :account_tag
  validates_uniqueness_of :tagged_post, :scope => :account_tag
    
  def self.fields_for_index
    [:tagged_post_id, :account_tag_id]
  end
  
  def self.fields_for_form
    {
      :tagged_post_id => :lookup,
      :account_tag_id => :lookup,
    }
  end
  
  def self.lookup
    :id
  end  
  
end
