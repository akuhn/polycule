require 'sinatra'
require 'sinatra/flash'
require 'mongo'
require 'haml'
require 'json'

if ENV['RACK_ENV'] == 'production'
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    username == ENV['MY_USER'] and password == ENV['MY_PASSWD']
  end
end

enable :sessions

require_relative 'model'

get '/' do
  haml :index
end

# People

get '/people' do
  @people = People.all
  haml :people
end

get '/person/new' do
  haml :person_new
end

post '/person/new' do
  p = People.new
  p[:name] = params[:name] unless params[:name].empty?
  p.fetch_facebook params[:fb]
  p.save!
  redirect "/people"
end

get '/person/:me' do
  @person = People.find_by_id params[:me]
  haml :person
end

delete '/person/:me' do
  @person = People.find_by_id params[:me]
  @person.delete!
  @person.relationships.each(&:delete!)
  flash[:notice] = "Person removed."
  redirect "/people"
end


# Relationships

get '/love/new' do
  @person = People.find_by_id params[:me]
  haml :love_new
end 

post '/love/new' do
  me = People.find_by_id params[:me]
  them = People.find_by_id params[:them]
  data = {
    me_id: me.id,
    them_id: them.id
  }
  Loves.new.update(data).save!
  redirect "/person/#{me.id}"
end

get '/love/:us' do
  @love = Loves.find_by_id params[:us]
  haml :love
end

delete '/love/:us' do
  @love = Loves.find_by_id params[:us]
  @love.delete!
  flash[:notice] = "Love removed."
  redirect "/person/#{@love.me_id}"
end




# Polycule visualization

get '/vis' do
  haml :vis
end

get '/vis/data.json' do
  index = Hash.new{|h,k|h[k]=h.size}
  content_type :json
  {
    nodes: People.all.collect do |each|
      index[each['_id'].to_s]
      {
        name: each.name,
        picture: each.picture(128)
      }
    end,
    links: Loves.all.collect do |each|
      {
        source: index[each['me_id'].to_s],
        target: index[each['them_id'].to_s]
      }
    end    
  }.to_json
end
