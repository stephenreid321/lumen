require File.expand_path(File.dirname(__FILE__) + '/test_config.rb')

class TestAccounts < ActiveSupport::TestCase
  include Capybara::DSL
    
  setup do
    Account.destroy_all
  end
      
  test 'signing in' do
    @account = create(:account)
    login_as(@account)
    assert page.has_content? 'Signed in'
  end
  
  test 'editing profile' do
    @account = create(:account)
    login_as(@account)
    click_link 'Edit profile & connect accounts'
    fill_in 'Name', :with => 'New Name'
    click_button 'Update account'
    assert page.has_content? 'Your account was updated successfully'
  end
    
end