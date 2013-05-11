require 'rubygems'
require 'mongo'

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
    fetch(name.to_s){super}
  end
  def id
    self['_id']
  end
  def save!
    raise if self.id 
    self.class.collection.insert(self)
  end
end

class People < Model
  def relationships
    id = self['_id']
    loves = Loves.find '$or' => [{me_id: id},{them_id: id}]
    loves.each{|love| love.swap unless love.me_id == id }
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
