ENV['RACK_ENV'] = 'test'

require_relative '../app'

require 'capybara'
require 'capybara/dsl'
require 'capybara/rspec'

Capybara.app = Sinatra::Application

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
set :session_secret, ''

module Helpers
  def within_form &block
    within('form',&block)
  end
  def submit!
    find('input[type=submit]').click 
  end
  def login! 
    visit '/login'
    within_form {
      fill_in 'username', with: 'adam'
      fill_in 'password', with: '***'
      submit!
    }
  end
end

RSpec.configure do |config|
  config.include Helpers
  config.before :suite do
    Loves.drop!
    People.drop!
    Polycules.drop!
    Users.drop!
  end
end

feature "Authentication" do

  scenario "Sign up as user" do
    
    visit '/'
    click_on "Log in"
    click_on "Sign up"
    within_form {
      fill_in 'username', with: 'adam'
      fill_in 'password', with: '***'
      fill_in 'confirm', with: '***'
      submit!
    }
    page.should have_content('Signed up')
    
  end

  scenario "Log in as user" do
    
    visit '/'
    click_on 'Log in'
    within_form {
      fill_in 'username', with: 'adam'
      fill_in 'password', with: '***'
      submit!
    }
    page.should have_content('Logged in')
  
  end

end

feature "People" do
  
  background { login! }

  scenario "Add person named Adam" do
    visit '/people'
    page.should_not have_content('Adam')
    click_on 'Add new person'
    within_form {
      fill_in 'name', with: 'Adam'
      submit!
    }
    current_path.should match '/person/[0-9a-f]+$'
  end

  scenario "List includes person named Adam" do
    visit '/people'
    page.should have_content('Adam')
  end
  
  scenario "Remove person named Adam" do
    visit '/people'
    click_on 'Adam'
    current_path.should match '/person/[0-9a-f]+$'
    click_on 'Remove'
    visit '/people'
    page.should_not have_content('Adam')
  end

end

feature "Loves" do
  
  background { login! }
  
  before(:all) { 
    scope = Polycules.find_one.id
    People.current(scope).create(name: 'Adam').save!
    People.current(scope).create(name: 'Eve').save!
  }
  
  scenario "Given Adam and Eve" do
    visit '/people'
    page.should have_content('Adam')
    page.should have_content('Eve')    
  end

  scenario "Add love" do
    visit '/people'
    click_on 'Adam'
    click_on 'Add new love'
    within_form {
      select 'Eve', from: 'them'
      submit!
    }
    page.should have_content('in love with Eve')
  end
  
  scenario "Adam should love Eve" do
    visit '/people'
    click_on 'Adam'
    page.should have_content('in love with Eve')
  end

  scenario "Eve should love Adam" do
    visit '/people'
    click_on 'Eve'
    page.should have_content('in love with Adam')
  end
    
  scenario "Edit love" do
    visit '/people'
    click_on 'Adam'
    click_on 'in love'
    click_on 'Edit this love'
    within_form {
      fill_in 'tags', with: 'its complicated'
      submit!
    }
    click_on 'Adam'
    page.should have_content('its complicated with Eve')
  end
  
end
