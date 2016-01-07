require File.expand_path(File.dirname(__FILE__) + '/test_config.rb')

class TestAccounts < ActiveSupport::TestCase
  include Capybara::DSL
    
  setup do
    Account.destroy_all
  end
      
  test 'signing in' do
    @account = FactoryGirl.create(:account)
    login_as(@account)
    assert page.has_content? 'Signed in'
  end
  
  test 'editing profile' do
    @account = FactoryGirl.create(:account)
    login_as(@account)
    visit '/me/edit'
    fill_in 'Name', :with => 'New Name'
    fill_in 'account[affiliations_attributes][0][title]', :with => 'Activist'
    fill_in 'account[affiliations_attributes][0][organisation_name]', :with => 'UK Uncut'
    page.execute_script(%Q{$("a:contains('Add another affiliation')").click()})    
    fill_in 'account[affiliations_attributes][1][title]', :with => 'Thinker'
    fill_in 'account[affiliations_attributes][1][organisation_name]', :with => 'University'    
    page.execute_script(%Q{$("a:contains('Add another area of expertise')").click()})    
    fill_in 'account[account_tagships_attributes][0][account_tag_name]', :with => 'ruby'
    click_button 'Update account'
    assert page.has_content? 'Your account was updated successfully'
  end
    
end