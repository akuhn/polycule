ENV['RACK_ENV'] = 'test'

require_relative '../app'

require 'rack/test'
require 'capybara'
require 'capybara/dsl'
require 'capybara/rspec'

Capybara.app = Sinatra::Application

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

feature "Authentication" do

  scenario "Log in with correct credentials" do
    
    visit '/'
    page.should have_content('My Polycule')
    click_on 'Log in'
    current_path.should == '/login' 
    within('form') do
      fill_in 'username', with: 'adam'
      fill_in 'password', with: '***'
      click_on 'Log in'
    end
    current_path.should == '/' 
    page.should have_content('Logged in')
  
  end

end

