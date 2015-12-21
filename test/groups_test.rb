require File.expand_path(File.dirname(__FILE__) + '/test_config.rb')

class TestGroups < ActiveSupport::TestCase
  include Capybara::DSL
    
  setup do
    Account.destroy_all    
    Group.destroy_all
  end
      
  test 'creating a group' do
    @account = FactoryGirl.create(:account)
    login_as(@account)
    visit '/groups'
    click_link 'Create a group'
    fill_in 'Name', :with => 'sparrow'
    choose 'Open'
    click_button 'Create group'
    assert page.has_content? 'The group was created successfully'
  end
  
  test 'creating a conversation' do
    @account = FactoryGirl.create(:account)
    @group = FactoryGirl.create(:group)    
    @group.memberships.create! :account => @account
    login_as(@account)
    visit '/'
    fill_in 'Subject', :with => 'oh hai'
    fill_in_summernote 'something very interesting'
    click_button 'Post'
    assert page.has_content? '1 participant in this conversation'
  end
  
  test 'replying to a conversation' do
    @account1 = FactoryGirl.create(:account)
    @account2 = FactoryGirl.create(:account)
    @group = FactoryGirl.create(:group)    
    @group.memberships.create! :account => @account1
    @group.memberships.create! :account => @account2
    @conversation = @group.conversations.create! :subject => 'black holes', :account => @account1
    @conversation.conversation_posts.create! :body => 'real dark', :account => @account1
    login_as(@account2)   
    visit '/'  
    click_link 'black holes'
    assert page.has_content? '1 participant in this conversation'
    fill_in_summernote 'i agree'
    click_button 'Post'
    assert page.has_content? '2 participants in this conversation'    
  end
    
end