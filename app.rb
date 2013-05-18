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

WHITELIST = %w{
  /
  /login
  /logout
  /signup
}

before do
  pass if WHITELIST.include? request.path_info
  if not session[:user]
    flash[:notice] = "You must login to access this page."
    redirect '/login' 
  end
end

helpers do
  def split_tags(string)
    string.split(/[,;]/).collect{|each| 
      each.scan(/\w+[\s\-\/]?/).join.downcase.strip 
    }.reject(&:empty?).sort
  end
  def current_user
    @user or @user = Users.with_id(session[:user])
  end
  def scope
    session[:polycule]
  end
end

get '/example' do
  content_type = :txt
  current_user.inspect
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

# Partition by current polycule

get '/polycules' do
  @polycules = Polycules.all
  haml :polycules
end

get '/polycules/new' do
  haml :polycules_new
end

post '/polycules' do
  data = {
    name: params[:name],
    owner: current_user.id,
    users: [current_user.id],
  }
  Polycules.new(data).save!
  redirect '/polycules'
end

get '/polycule/:current' do
  @polycule = Polycules.with_id params[:current]
  session[:polycule] = @polycule.id
  redirect '/people'
end


# People

get '/people' do
  @people = People.current(scope).all
  haml :people
end

get '/people/new' do
  haml :people_new
end

post '/people' do
  @person = People.current(scope).new
  @person.name = params[:name]
  @person.fetch_facebook params[:fb]
  @person.fetch_okcupid params[:okc]
  @person.save!
  flash[:notice] = "Person added." 
  redirect "/person/#{@person.id}"
end

get '/person/:me/edit' do
  @person = People.current(scope).with_id params[:me]
  haml :person_edit
end

put '/person/:me' do
  @person = People.current(scope).with_id params[:me]
  @person[:name] = params[:name]
  @person[:gender] = params[:gender]
  @person[:location] = params[:location]
  @person.fetch_facebook params[:fb] unless @person.fb.username == params[:fb]
  @person.fetch_okcupid params[:okc] unless @person.okc.username == params[:okc]
  @person.update!
  redirect "/person/#{@person.id}"
end

get '/person/:me' do
  @person = People.current(scope).with_id params[:me]
  haml :person
end

delete '/person/:me' do
  @person = People.current(scope).with_id params[:me]
  @person.delete!
  @person.relationships.each(&:delete!)
  flash[:notice] = "Person removed."
  redirect "/people"
end


# Relationships

get '/loves/new' do
  @person = People.current(scope).with_id params[:me]
  haml :loves_new
end 

post '/loves' do
  me = People.current(scope).with_id params[:me]
  them = People.current(scope).with_id params[:them]
  data = {
    me_id: me.id,
    them_id: them.id,
    tags: split_tags(params[:tags])
  }
  Loves.current(scope).new.update(data).save!
  redirect "/person/#{me.id}"
end

get '/love/:us' do
  @love = Loves.current(scope).with_id params[:us]
  haml :love
end

delete '/love/:us' do
  @love = Loves.current(scope).with_id params[:us]
  @love.delete!
  flash[:notice] = "Love removed."
  redirect "/person/#{@love.me_id}"
end

get '/love/:us/edit' do
  @love = Loves.current(scope).with_id params[:us]
  haml :love_edit
end

put '/love/:us' do
  @love = Loves.current(scope).with_id params[:us]
  @love[:tags] = split_tags(params[:tags])
  @love.update!
  redirect "/love/#{@love.id}"
end




# Polycule visualization

get '/vis' do
  haml :vis
end

get '/vis/data.json' do
  index = Hash.new{|h,k|h[k]=h.size}
  content_type :json
  {
    nodes: People.current(scope).all.collect do |each|
      index[each.id.to_s]
      {
        name: each.name,
        picture: each.picture(128)
      }
    end,
    links: Loves.current(scope).all.collect do |each|
      {
        source: index[each.me_id.to_s],
        target: index[each.them_id.to_s]
      }
    end    
  }.to_json
end
