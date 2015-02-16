class SurveyTaker
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :survey, index: true
  belongs_to :account, index: true
    
  has_many :answers, :dependent => :destroy
  accepts_nested_attributes_for :answers, allow_destroy: true, reject_if: :all_blank
  
  validates_presence_of :survey, :account
  
  validates_uniqueness_of :account, :scope => :survey
    
  def self.admin_fields
    {
      :survey_id => :lookup,
      :account_id => :lookup,
      :answers => :collection,
    }
  end
    
end
