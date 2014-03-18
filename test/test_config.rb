RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path('../../config/boot', __FILE__)

require 'capybara'
require 'capybara/poltergeist'
require 'factory_girl'
require 'minitest/autorun'

Capybara.app = Padrino.application
Capybara.server_port = 3001
Capybara.default_driver = :poltergeist

class MiniTest::Unit::TestCase
  include FactoryGirl::Syntax::Methods
end

FactoryGirl.define do
  
  factory :account do
    sequence(:name) { |n| "Account #{n}" }
    sequence(:email) { |n| "account#{n}@example.com" }
    time_zone 'London'
    sequence(:password) { |n| "password#{n}" } 
    password_confirmation { password }
  end
  
  factory :group do
    sequence(:slug) { |n| "group-#{n}" }
    privacy 'Open'
  end  
  
end

class ActiveSupport::TestCase

  def login_as(account)
    visit '/accounts/sign_in'
    fill_in 'Email', :with => account.email
    fill_in 'Password', :with => account.password
    click_button 'Sign in'    
  end
  
  def fill_in_wysihtml5(text)
    page.execute_script("editor.setValue('#{text}')")
  end
  
end

