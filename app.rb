require 'sinatra'
require 'sinatra/flash'
require 'bcrypt'
require 'mongo'
require 'haml'
require 'json'

require_relative 'model'

enable :sessions

set :session_secret, ENV['MY_SECRET']

configure :production do
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username == ENV['MY_USER'] and password == ENV['MY_PASSWD']
  end
end

set :auth do |roles|
  condition do
    unless session[:user]
      flash[:notice] = "You must login to access this page."
      redirect '/login' 
    end
  end
end

# Learning from http://128bitstudios.com/2011/11/21/authentication-with-sinatra

get '/signup' do
  haml :signup
end

post '/signup' do
  if not params[:password] == params[:confirm] then
    flash[:notice] = "Passwords did not match."
    redirect '/signup'
  end
  salt = BCrypt::Engine.generate_salt
  hash = BCrypt::Engine.hash_secret params[:password], salt
  data = {
    username: params[:username],
    salt: salt,
    password_hash: hash,
  }
  Users.new.merge(data).save!
  flash[:notice] = "Signed up, log in to log in."
  redirect '/'
end
 
get '/login' do
  haml :login
end

post '/login' do
  user = Users.find_one username: params[:username]
  hash = BCrypt::Engine.hash_secret params[:password], user.salt
  raise unless user.password_hash == hash
  session[:user] = user.id
  session[:username] = user.username
  flash[:notice] = "Logged in as #{user.username}."
  redirect '/'
end

get '/logout' do
  session[:user] = nil
  session[:username] = nil
  flash[:notice] = "Logged out."
  redirect '/'
end

get '/' do
  haml :index
end

# People

get '/people', :auth => :user do
  @people = People.all
  haml :people
end

get '/person/new', :auth => :user do
  haml :person_new
end

post '/person/new', :auth => :user do
  p = People.new
  p[:name] = params[:name] unless params[:name].empty?
  p.fetch_facebook params[:fb]
  p.fetch_okcupid params[:okc]
  p.save!
  redirect "/people"
end

get '/person/:me/edit', :auth => :user do
  @person = People.find_by_id params[:me]
  haml :person_edit
end

post '/person/:me/edit', :auth => :user do
  p = People.find_by_id params[:me]
  p[:name] = params[:name] unless params[:name].empty?
  p.fetch_facebook params[:fb] unless p.fb.username == params[:fb]
  p.fetch_okcupid params[:okc] unless p.okc.username == params[:okc]
  p.update!
  redirect "/person/#{p.id}"
end

get '/person/:me', :auth => :user do
  @person = People.find_by_id params[:me]
  haml :person
end

delete '/person/:me', :auth => :user do
  @person = People.find_by_id params[:me]
  @person.delete!
  @person.relationships.each(&:delete!)
  flash[:notice] = "Person removed."
  redirect "/people"
end


# Relationships

get '/love/new', :auth => :user do
  @person = People.find_by_id params[:me]
  haml :love_new
end 

post '/love/new', :auth => :user do
  me = People.find_by_id params[:me]
  them = People.find_by_id params[:them]
  data = {
    me_id: me.id,
    them_id: them.id
  }
  Loves.new.update(data).save!
  redirect "/person/#{me.id}"
end

get '/love/:us', :auth => :user do
  @love = Loves.find_by_id params[:us]
  haml :love
end

delete '/love/:us', :auth => :user do
  @love = Loves.find_by_id params[:us]
  @love.delete!
  flash[:notice] = "Love removed."
  redirect "/person/#{@love.me_id}"
end




# Polycule visualization

get '/vis', :auth => :user do
  haml :vis
end

get '/vis/data.json', :auth => :user do
  index = Hash.new{|h,k|h[k]=h.size}
  content_type :json
  {
    nodes: People.all.collect do |each|
      index[each.id.to_s]
      {
        name: each.name,
        picture: each.picture(128)
      }
    end,
    links: Loves.all.collect do |each|
      {
        source: index[each.me_id.to_s],
        target: index[each.them_id.to_s]
      }
    end    
  }.to_json
end
