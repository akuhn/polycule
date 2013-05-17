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

helpers do
  def split_tags(string)
    string.split(/[,;]/).collect{|each| 
      each.scan(/\w+[\s\-\/]?/).join.downcase.strip 
    }.reject(&:empty?).sort
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
    email: params[:email],
    salt: salt,
    password_hash: hash,
    pending_confirmation: true,
    token: rand(1e20).to_s
  }
  @user = Users.new(data)
  @user.save!
  p "Sending email to #{@user.email} with http://localhost:9393/signup/#{@user.token}"
  flash[:notice] = "Confirmation email sent!"
  redirect '/'
end

get '/signup/:token' do
  @user = Users.find_one token: params[:token]
  @user.delete(:pending_confirmation)
  @user.delete(:token)
  @user[:active] = true
  @user.update!
  flash[:notice] = "Email confirmed."
  redirect '/login'
end
 
get '/login' do
  haml :login
end

post '/login' do
  @user = Users.find_one username: params[:username]
  hash = BCrypt::Engine.hash_secret params[:password], @user.salt
  raise unless @user.password_hash == hash
  raise unless @user[:active]
  session[:user] = @user.id
  session[:username] = @user.username
  flash[:notice] = "Logged in as #{@user.username}."
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
  @person = People.new
  @person.name = params[:name]
  @person.fetch_facebook params[:fb]
  @person.fetch_okcupid params[:okc]
  @person.save!
  flash[:notice] = "Person added." 
  redirect "/person/#{@person.id}"
end

get '/person/:me/edit', :auth => :user do
  @person = People.find_by_id params[:me]
  haml :person_edit
end

post '/person/:me/edit', :auth => :user do
  @person = People.find_by_id params[:me]
  @person[:name] = params[:name]
  @person[:gender] = params[:gender]
  @person[:location] = params[:location]
  @person.fetch_facebook params[:fb] unless @person.fb.username == params[:fb]
  @person.fetch_okcupid params[:okc] unless @person.okc.username == params[:okc]
  @person.update!
  redirect "/person/#{@person.id}"
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
    them_id: them.id,
    tags: split_tags(params[:tags])
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

get '/love/:us/edit', :auth => :user do
  @love = Loves.find_by_id params[:us]
  haml :love_edit
end

post '/love/:us/edit', :auth => :user do
  @love = Loves.find_by_id params[:us]
  @love[:tags] = split_tags(params[:tags])
  @love.update!
  redirect "/love/#{@love.id}"
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
