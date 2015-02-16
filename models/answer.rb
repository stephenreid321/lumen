class Answer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, :type => String
  
  belongs_to :question, index: true    
  belongs_to :survey_taker, index: true
  
  belongs_to :survey, index: true
  belongs_to :account, index: true
  
  validates_presence_of :text, :question, :survey_taker, :survey, :account
    
  before_validation do
    self.survey = self.question.survey if self.question
    self.account = self.survey_taker.account if self.survey_taker
  end   
    
  def self.admin_fields
    {
      :text => :text_area,
      :question_id => :lookup,
      :survey_taker_id => :lookup,
      :account_id => :lookup,
      :survey_id => :lookup
    }
  end

 end
