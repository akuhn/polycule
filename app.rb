require 'sinatra'
require 'mongo'
require 'haml'
require 'json'

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


# Polycule visualization

get '/vis' do
  raise
end

get '/polycule/data.json' do
  content_type :json
  {
    edges: Loves.all.collect do |each|
      {
        source: each['me_id'].to_s,
        target: each['them_id'].to_s
      }
    end,
    nodes: People.all.collect do |each|
      {
        id: each['_id'].to_s,
        name: each.name
      }
    end
  }.to_json
end
