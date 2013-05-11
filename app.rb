require 'sinatra'
require 'mongo'
require 'haml'

DB = Mongo::Connection.new("localhost", 27017).db('polycule')

PEOPLE = DB['people']
LOVES = DB['loves']

# require 'pry'; binding.pry

get '/' do
  haml :index
end

# People

get '/people' do
  @people = PEOPLE.find
  haml :people
end

get '/person/new' do
  haml :person_new
end

post '/person/new' do
  person = {
    name: params[:name],
    fb: params[:fb]
  }
  p person
  id = PEOPLE.insert(person)
  redirect "/people"
end

get '/person/:me' do
  me = BSON::ObjectId.from_string(params[:me])
  @person = PEOPLE.find_one(_id: me)
  @loves = LOVES.find('$or' => [{ me: me },{ them: me }])
  
  
  haml :person
end

# Relationships

get '/love/new' do
  me = BSON::ObjectId.from_string(params[:me])
  @person = PEOPLE.find_one(_id: me)
  @people = PEOPLE.find(_id: {'$ne' => me})
  haml :love_new
end 

post '/love/new' do
  me = BSON::ObjectId.from_string(params[:me])
  them = BSON::ObjectId.from_string(params[:them])
  data = {
    me: me,
    them: them
  }
  id = LOVES.insert(data)
  redirect "/person/#{me}"
end

get '/love/:us' do
  us = BSON::ObjectId.from_string(params[:us])
  @love = LOVES.find_one(_id: us)
  haml :love
end


# Polycule visualization

get '/polycule' do
  raise
end


