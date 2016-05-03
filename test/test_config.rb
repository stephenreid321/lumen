$VERBOSE = nil
RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path('../../config/boot', __FILE__)

Rack::Timeout::Logger.disable
ActiveSupport::TestCase.test_order = :sorted

require 'dragonfly'

require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'factory_girl'
require 'minitest/autorun'
require 'minitest/rg'

Capybara.app = Padrino.application
Capybara.server_port = ENV['PORT']
Capybara.default_driver = :poltergeist

FactoryGirl.define do
  
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
    sequence(:email) { |n| "account#{n}@example.com" }
    time_zone 'London'
    sequence(:password) { |n| "password#{n}" } 
    password_confirmation { password }
  end
  
  factory :group do
    sequence(:name) { |n| "Test Group #{n}" }
    sequence(:slug) { |n| "test-group-#{n}" }
    privacy 'Open'
  end  
  
end

class ActiveSupport::TestCase
  
  setup do
    Language.create :name => 'English', :code => 'en', :default => true
  end

  def login_as(account)
    visit '/accounts/sign_in'
    fill_in 'Email', :with => account.email
    fill_in 'Password', :with => account.password
    click_button 'Sign in'    
  end
    
  def fill_in_summernote(text)
    page.execute_script("$('.summernote').code('#{text}')")
  end

end

