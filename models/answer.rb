class Answer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, :type => String
  
  belongs_to :survey
  belongs_to :question  
  belongs_to :account
    
  validates_presence_of :text, :survey, :question, :account
  
  validates_uniqueness_of :account, :scope => :question
  
  before_validation :set_survey
  def set_survey
    self.survey = self.question.try(:survey)
  end   
    
  def self.admin_fields
    {
      :text => :text_area,
      :survey_id => :lookup,
      :question_id => :lookup,
      :account_id => :lookup
    }
  end
    
  def account_name
    account.name
  end
 
end
