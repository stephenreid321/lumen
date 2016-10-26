class Position
  include Mongoid::Document
  include Mongoid::Timestamps

  field :status, :type => String
  field :reason, :type => String
  
  belongs_to :proposal
  belongs_to :account
  
  def self.statuses
    %w{agree abstain disagree block}
  end
  
  validates_presence_of :status
  validates_uniqueness_of :account_id, :scope => :proposal_id
    
  def self.admin_fields
    {
      :status => :select,
      :reason => :text_area,
      :account_id => :lookup,
      :proposal_id => :lookup
    }
  end
  
  def actioned
    case status; when 'agree'; 'agreed with'; when 'abstain'; 'abstained on'; when 'disagree'; 'disagreed with'; when 'block'; 'blocked'; end
  end
  
  after_save do
    conversation = proposal.conversation
    conversation_post = conversation.conversation_posts.create!(
      :body => %Q{<p><a href="http://#{Config['DOMAIN']}/accounts/#{account_id}">#{account.name}</a> <strong>#{actioned.split(' ').first}</strong>#{%Q{ #{actioned.split(' ').last}} if actioned.split(' ').length == 2} the proposal <strong>#{proposal.title}</strong>#{':' if reason}</p><p>#{reason}</p><p class="hidden" style="font-size: 12px">State your position at <a href="http://#{Config['DOMAIN']}/conversations/#{conversation.slug}">http://#{Config['DOMAIN']}/conversations/#{conversation.slug}</a></p>},
      :account => account)
    conversation_post.send_notifications!  
  end  
      
end
