class ConversationPost
  include Mongoid::Document
  include Mongoid::Timestamps

  field :body, :type => String
  field :imap_uid, :type => String
  field :message_id, :type => String
  field :hidden, :type => Boolean, :default => false
  field :link_title, :type => String
  field :link_url, :type => String
  field :link_description, :type => String  
  field :link_picture, :type => String
  field :link_player, :type => String
  
  belongs_to :conversation, index: true
  belongs_to :group, index: true
  belongs_to :account, index: true
  
  has_many :conversation_post_bccs, :dependent => :destroy
  has_many :conversation_post_bcc_recipients, :dependent => :destroy
  has_many :conversation_post_read_receipts, :dependent => :destroy
  
  if Config['BCC_SINGLE']
    def conversation_post_bcc
      conversation_post_bccs.first
    end
  end
  
  has_many :attachments, :dependent => :destroy
  accepts_nested_attributes_for :attachments
  has_many :likes, :dependent => :destroy
  
  validates_presence_of :body, :account, :conversation, :group  
  validates_uniqueness_of :imap_uid, :scope => :group, :allow_nil => true    
  validates_uniqueness_of :message_id, :allow_nil => true
      
  index({imap_uid: 1 })
  index({message_id: 1}, {unique: true, sparse: true})
  
  before_validation :set_group
  def set_group
    self.group = self.conversation.try(:group)
  end
      
  def self.admin_fields
    {
      :id => {:type => :text, :index => false},
      :body => :wysiwyg,
      :imap_uid => :text,
      :message_id => :text,
      :account_id => :lookup,      
      :conversation_id => :lookup,
      :group_id => :lookup,      
      :hidden => :check_box,      
      :link_title => :text,
      :link_url => :text,
      :link_description => :text_area,
      :link_picture => :text,
      :link_player => :text,      
      :conversation_post_bccs => :collection,
      :conversation_post_read_receipts => :collection      
    }
  end
  
  attr_accessor :file
  before_validation :set_attachment
  def set_attachment
    if self.file
      self.attachments.build file: self.file
      self.file = nil
    end  
  end
  
  def account_name
    account.name
  end
  
  before_validation :check_membership_is_not_muted
  def check_membership_is_not_muted
    errors.add(:account, 'is muted') if self.group.memberships.find_by(account: self.account, muted: true)
  end   
  
  after_create :touch_conversation
  def touch_conversation
    conversation.update_attribute(:updated_at, Time.now) unless conversation.hidden
  end
  
  def didyouknow_replacements(string)
    group = conversation.group
    members = group.members
    string.gsub!('[site_url]', "#{Config['SSL'] ? 'https://' : 'http://'}#{Config['DOMAIN']}")
    string.gsub!('[name]', group.name)
    string.gsub!('[slug]', group.slug)        
    string.gsub!('[conversation_url]', "#{Config['SSL'] ? 'https://' : 'http://'}#{Config['DOMAIN']}/conversations/#{conversation.slug}")
    string.gsub!('[members]', "#{m = members.count} #{m == 1 ? 'member' : 'members'}")
    string.gsub!('[upcoming_events]', "#{e = group.events.where(:start_time.gt => Time.now).count} #{e == 1 ? 'upcoming event' : 'upcoming events'}")
    most_recently_updated_account = members.order_by([:has_picture.desc, :updated_at.desc]).first
    string.gsub!('[most_recently_updated_url]', "#{Config['SSL'] ? 'https://' : 'http://'}#{Config['DOMAIN']}/accounts/#{most_recently_updated_account.id}")
    string.gsub!('[most_recently_updated_name]', most_recently_updated_account.name)
    string
  end  
  
  def self.dmarc_fail_domains
    %w{yahoo.com aol.com protonmail.com} + (Config['DMARC_FAIL_DOMAINS'] ? Config['DMARC_FAIL_DOMAINS'].split(',') : [])
  end

  def from_address
    group = conversation.group
    from = account.email
    if ConversationPost.dmarc_fail_domains.include?(from.split('@').last)
      group.email('-noreply')
    else
      from
    end
  end    
   
  def accounts_to_notify   
    Account.where(:id.in => (group.memberships.where(:status => 'confirmed').where(:notification_level => 'each').pluck(:account_id) - conversation.conversation_mutes.pluck(:account_id)))
  end
        
  def send_notifications!(force: false)
    # force may help with caching issues
    unless force
      return if conversation.hidden
    end
    if Config['BCC_SINGLE']
      if Config['BCC_SINGLE_JOB']
        Delayed::Job.enqueue BccSingleJob.new(self.id)
      else
        bcc_single
      end               
    else
      Delayed::Job.enqueue BccEachJob.new(self.id)
    end
  end
        
  def replace_cids!
    self.body = body.gsub(/src="cid:(\S+)"/) { |match|
      begin
        %Q{src="#{Config['SSL'] ? 'https://' : 'http://'}#{Config['DOMAIN']}#{attachments.find_by(cid: $1).file.url}"}
      rescue
        nil
      end
    }    
    self.body = body.gsub(/\[cid:(\S+)\]/) { |match|
      begin
        %Q{<img src="#{Config['SSL'] ? 'https://' : 'http://'}#{Config['DOMAIN']}#{attachments.find_by(cid: $1).file.url}">}
      rescue
        nil
      end
    }    
    self
  end
  
  def replace_iframes!
    self.body = body.gsub(/(<iframe\b[^>]*><\/iframe>)/) do |match|
      src = Nokogiri::HTML.parse($1).search('iframe').first['src']
      %Q{<a href="#{src}">#{src}</a>}
    end
    self
  end
  
  def bcc_single    
    conversation_post_bccs.create(accounts: accounts_to_notify)
  end  
  
  def bcc_each
    conversation_post = self
        
    array = conversation_post.accounts_to_notify
    return if array.length == 0
    
    no_of_threads = Config['BCC_EACH_THREADS'] || 10
    
    slice_size = (array.length/Float(no_of_threads)).ceil
    slices = array.each_slice(slice_size).to_a
    puts "splitting into #{slices.length} groups of #{slices.map(&:length).join(', ')}"
    threads = []

    slices.each_with_index { |slice, i|
      threads << Thread.new(slice, i) do |slice, i|
        slice.each { |account|
          begin
            conversation_post.conversation_post_bccs.create(accounts: [account])
          rescue => e
            Airbrake.notify(e)
          end
        }      
      end
    }
    threads.each { |thread| thread.join }  
  end
  
  def self.check_for_missing_bccs_and_message_ids(since: 1.hour.ago)
    ConversationPost.where(:created_at.gt => since).each { |conversation_post|
      if conversation_post.conversation_post_bccs.empty?
        begin
          raise (r = "no bccs: #{conversation_post.conversation.subject} #{conversation_post.id}")
        rescue => e
          puts r
          Airbrake.notify(e)
        end      
      end
      if conversation_post.conversation_post_bccs.where(message_id: nil).count > 0
        begin
          raise (r = "bcc with no message_id: #{conversation_post.conversation.subject} #{conversation_post.id}")
        rescue => e
          puts r
          Airbrake.notify(e)
        end        
      end
    }    
  end  
  
end
