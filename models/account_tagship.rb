class AccountTagship
  include Mongoid::Document
  include Mongoid::Timestamps
    
  belongs_to :account, index: true  
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
  
  after_create :join_associated_groups
  def join_associated_groups
    account_tag.group_join_tagships.each { |group_join_tagship|
      group = group_join_tagship.group
      group.memberships.create!(account: account)
    }
  end
  
  validates_presence_of :account, :account_tag
  validates_uniqueness_of :account, :scope => :account_tag
    
  def self.fields_for_index
    [:account_id, :account_tag_id]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :account_tag_id => :lookup,
    }
  end
  
  def self.lookup
    :id
  end  
  
end
