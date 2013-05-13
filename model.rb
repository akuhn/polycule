require 'rubygems'
require 'mongo'
require 'json'
require 'net/http'

DB = Mongo::Connection.new("localhost", 27017).db('polycule')

class Model < Hash
  class <<self
    def collection
      DB[name.downcase]
    end
    def all
      collection.find.collect{|each|self.new.merge(each)}
    end
    def find_by_id id
      id = BSON::ObjectId.from_string(id) if String === id
      self.new.merge(collection.find_one({_id: id}))
    end
    def find query
      collection.find(query).collect{|each|self.new.merge(each)}
    end
  end
  def method_missing(name,*args)
    value = self[name.to_s]
    return super unless value
    value = Model.new.update(value) if Hash === value
    return value
  end
  def id
    fetch('_id'){fetch('id'){raise}}
  end
  def save!
    raise if self['_id'] 
    self.class.collection.insert(self)
  end
end

class People < Model
  def relationships
    id = self['_id']
    loves = Loves.find '$or' => [{me_id: id},{them_id: id}]
    loves.each{|love| love.swap unless love.me_id == id }
  end
  def fetch_facebook url
    p path = "/#{URI.parse(url).path}"
    p r = Net::HTTP.get_response('graph.facebook.com',path)
    return unless r.code == "200"
    self['fb'] = JSON.parse(r.body)
  end
  def name
    self['name'] or (self['fb'] and self['fb']['name']) or 'A person'
  end
  def picture
    "https://graph.facebook.com/#{self.fb.id}/picture" if self['fb']
  end
end

class Loves < Model
  def swap
    self['me_id'],self['them_id'] = self['them_id'],self['me_id']
  end
  def them
    @them or @them = People.find_by_id(them_id)
  end
  def me
    @me or @me = People.find_by_id(me_id)
  end
end
