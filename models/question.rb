class Question
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, :type => String
  field :help, :type => String
  field :type, :type => String
  field :options, :type => String
  
  belongs_to :survey
  
  has_many :answers, :dependent => :destroy
  
  validates_presence_of :text, :type, :survey
  
  def self.types
    {
      'Single line text' => :text,
      'Paragraph text' => :text_area,
      'Check box' => :check_box,
      'Select box' => :select,      
      'Radio buttons (select one)' => :radio_buttons,
      'Check boxes (select multiple)' => :check_boxes
    }
  end
    
  def options_a
    q = (options || '').split("\n").map(&:strip) 
    q.empty? ? [] : q
  end
    
  def self.admin_fields
    {
      :text => :text_area,
      :help => :text_area,
      :type => :select,
      :options => :text_area,
      :survey_id => :lookup,
      :answers => :collection
    }
  end
  
end
