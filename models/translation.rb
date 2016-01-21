class Translation
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :key, :type => String
  field :value, :type => String  
  
  index({key: 1 }, {unique: true})
  
  belongs_to :language, index: true
  
  validates_presence_of :key, :value, :language
  validates_uniqueness_of :key, :scope => :language
    
  def self.admin_fields
    {
      :language_id => :lookup,
      :key => :text,
      :value => :text
    }
  end
  
  def summary
    "#{key}: #{value}"
  end
    
  def self.defaults
    {
      :home => 'home',
      :my_groups => 'my groups',
      :all_groups => 'all groups',
      :edit_profile => 'edit profile',
      :sign_out => 'sign out',
      :sign_in => 'sign in',
      :edit => 'edit',
      :organisation => 'organisation',
      :organisations => 'organisations',
      :host_organisation => 'host organisation',
      :sector => 'sector',
      :sectors => 'sectors',
      :position => 'position',
      :positions => 'positions',      
      :account_tagship => 'area of expertise',
      :account_tagships => 'areas of expertise',
      :add_another_account_tagship => 'add another area of expertise',      
      :news => 'news',
      :digest => 'digest',
      :map => 'map',
      :docs => 'docs',
      :surveys => 'surveys',
      :stats => 'stats',
      :calendar => 'calendar',
      :events => 'events',
      :conversations => 'conversations',
      :welcome_to => 'welcome to',
      :affiliations => 'affiliations',
      :groups => 'groups',
      :add_another_affiliation => 'add another affiliation',      
      :'members.one' => '1 member',
      :'members.other' => '%{count} members',
      :'members_in_this_group.one' => '1 member in this group',
      :'members_in_this_group.other' => '%{count} members in this group',
      :'people_in_your_groups.one' => '1 person in your groups',
      :'people_in_your_groups.other' => '%{count} people in your groups',
      :'mongoid.attributes.account.name' => 'Name',
      :'mongoid.attributes.account.email' => 'Email',
      :'mongoid.attributes.account.phone' => 'Phone',
      :'mongoid.attributes.account.website' => 'Website',
      :'mongoid.attributes.account.time_zone' => 'Time zone',
      :'mongoid.attributes.account.language_id' => 'Language',
      :'mongoid.attributes.account.twitter_profile_url' => 'Twitter profile URL',
      :'mongoid.attributes.account.facebook_profile_url' => 'Facebook profile URL',
      :'mongoid.attributes.account.google_profile_url' => 'Google+ profile URL',
      :'mongoid.attributes.account.linkedin_profile_url' => 'LinkedIn profile URL',
      :'mongoid.attributes.account.picture' => 'Picture',
      :'mongoid.attributes.account.password' => 'Password',
      :'mongoid.attributes.account.password_confirmation' => 'Password again',      
      :'mongoid.attributes.account.location' => 'Location',
      :'mongoid.attributes.account.town' => 'Town/city',
      :'mongoid.attributes.account.postcode' => 'Postcode',
      :'mongoid.attributes.account.country' => 'Country',
      :'mongoid.attributes.account.headline' => 'Headline',
      :delete_account => 'delete account',
      :delete_account_instructions => "To completely remove your account, type your name into the box below and click 'Delete account'.",                
      :update_account => 'update account',
      :filter_by_name => 'filter by name',
      :filter_by_organisation => 'filter by organisation',
      :filter_by_account_tagship => 'filter by area of expertise',
      :filter_by_sector => 'filter by sector',
      :member_of => 'member of',
      :at => 'at',
      :date_joined => 'date joined',
      :name => 'name',
      :last_updated => 'last updated',
      :sort_by => 'sort by',
      :'will_paginate.previous_label' => '&#8592; Previous',
      :'will_paginate.next_label' => 'Next &#8594;',
      :'will_paginate.page_gap' => '&hellip;',
      :'will_paginate.page_entries_info.single_page.zero' => 'No %{model} found',
      :'will_paginate.page_entries_info.single_page.one' => 'Displaying 1 %{model}',
      :'will_paginate.page_entries_info.single_page.other' => 'Displaying all %{count} %{model}',
      :'will_paginate.page_entries_info.single_page_html.zero' => 'No %{model} found',
      :'will_paginate.page_entries_info.single_page_html.one' => 'Displaying <b>1</b> %{model}',
      :'will_paginate.page_entries_info.single_page_html.other' => 'Displaying <b>all&nbsp;%{count}</b> %{model}',
      :'will_paginate.page_entries_info.multi_page' => 'Displaying %{model} %{from} - %{to} of %{count} in total',
      :'will_paginate.page_entries_info.multi_page_html' => 'Displaying %{model} <b>%{from}&nbsp;-&nbsp;%{to}</b> of <b>%{count}</b> in total',
      :manage_members => 'manage members',
      :settings => 'settings',
      :emails => 'emails',
      :landing_tab => 'landing tab',
      :did_you_know => 'did you know...',
      :analytics => 'analytics',
      :email_notifications => 'email notifications',
      :join_group => 'join group',
      :leave_group => 'leave group',
      :leave_group_confirm => 'Are you sure you want to leave this group?',
      :on => 'on',
      :off => 'off',
      :weekly_digest => 'weekly digest',
      :daily_digest => 'daily digest',
      :you_can_also_send_a_mail_to => 'You can also send an email to',
      :fill_out_the_form_below_or_send_a_mail_to => 'Fill out the form below or send an email to',
      :last_post => 'last post',
      :new_conversation => 'new conversation',
      :group_conversations => "%{slug}'s conversations",
      :digest_for_group => "digest for %{slug}",
      :digest_for_your_groups => 'digest for your groups',
      :people => 'people',
      :venues => 'venues',
      :capacity_of_at_least => 'capacity of at least',
      :accessible => 'accessible',
      :private_room_available => 'private room available',
      :serves_food => 'serves food',
      :serves_alcohol => 'serves alcohol',
      :maximum_hourly_cost => 'maximum hourly cost',
      :search => 'search',
      :add_a_venue => 'add a venue',
      :surveys_for_group => "surveys for %{slug}",
      :surveys_for_your_groups => 'surveys for your groups',      
      :docs_for_group => "docs for %{slug}",
      :docs_for_your_groups => 'docs for your groups',            
      :hot_conversations => 'hot conversations',
      :new_events => 'new events',
      :add_an_event => 'add an event',
      :new_people => 'new people',
      :view_all_people => 'view all people',
      :upcoming_events => 'upcoming events',
      :created => 'created',
      :attach_a_file => 'attach a file',
      :post => 'post'
    }.merge(Hash[GroupType.all.map { |group_type| ["group_type.#{group_type.slug}", group_type.name] } ])
  end
      
end
