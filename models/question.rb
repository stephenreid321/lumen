class Question
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, :type => String
  field :help, :type => String
  field :type, :type => String
  field :options, :type => String
  field :order, :type => Integer
  field :required, :type => Boolean
  
  belongs_to :survey, index: true
  
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
      :required => :check_box,
      :order => :number,
      :survey_id => :lookup,
      :answers => :collection
    }
  end
  
end
