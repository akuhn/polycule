require 'rubygems'
require 'mongo'
require 'json'
require 'net/http'

require_relative 'okcupid'

if ENV['RACK_ENV'] == 'production'
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  DB = Mongo::Connection.new(db.host, db.port).db(db_name)
  DB.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
else
  DB = Mongo::Connection.new("localhost", 27017).db('polycule')
end

# Meta-programming to use hashes as objects

class Document < Hash
  class <<self
    def schema
      @schema ||= Hash.new
    end
    def attr name, type=nil
      schema[name] = type
      if type
        module_eval %{ def #{name}; self.fetch(:#{name}){self[:#{name}]=self.class.schema[:#{name}].new}; end } 
      else
        module_eval %{ def #{name}; self[:#{name}]; end }
        module_eval %{ def #{name}=value; self[:#{name}]=value; end }
      end
      module_eval %{ def #{name}?; not nil_or_empty? self[:#{name}]; end }
    end
    def with *fields
      h = Hash.new
      h.update(fields.pop) if Hash === fields.last 
      fields.each{|name|h[name]=nil}
      doc = Class.new(Document)
      h.each{|name,type|doc.attr(name,type)}
      return doc
    end
  end
  def initialize(hash=nil)
    return unless hash
    schema = self.class.schema
    hash.each do |name,each|
      name = name.to_sym # symbolize all names
      each = schema[name].new(each) if schema[name]
      self[name] = each
    end
  end
  def compact
    each{|name,each|self.delete(name) if nil_or_empty? each}
  end
  def method_missing(name,*args)
    self.fetch(name){super}
  end
  def respond_to_missing?(name,*args)
    self.include?(name) or super
  end
  private
  def nil_or_empty? value
    value.nil? || value.respond_to?(:empty?) && value.empty?
  end
end

# Object-document mapper

module Query
  def create data={}
    document.new scope.merge(data)
  end
  def all
    find({})
  end
  def find query
    found = document.collection.find scope.merge(query)
    found.collect{|each|document.new each}
  end
  def with_id id
    id = BSON::ObjectId.from_string(id) if String === id
    find_one _id: id 
  end
  def find_one query
    found = document.collection.find_one scope.merge(query)
    document.new found if found
  end
end

module Update
  def id
    fetch(:_id){raise}
  end
  def id?
    self.include?(:_id)
  end
  def save!
    raise if self.id? 
    self.class.collection.insert(self.compact)
  end
  def update!
    raise unless self.id? 
    self.class.collection.update({_id: self.id}, self.compact)
  end
  def delete!
    raise unless self.id? 
    self.class.collection.remove(_id: self.id)
  end
end

class Collection < Document
  class <<self
    include Query
    def collection
      DB[name.downcase]
    end
    def document
      self
    end
    def scope
      {}
    end
  end
  include Update
end  

class Scope
  include Query
  attr_reader :document,:scope
  def initialize(type,scope)
    @document = type
    @scope = {scope: scope}
  end
end

class CollectionWithScope < Document
  class <<self
    def current scope
      Scope.new self, scope
    end
    def collection
      DB[name.downcase]
    end
  end
  include Update
end

# Application model

class People < CollectionWithScope
  attr :name
  attr :gender
  attr :location
  attr :fb, Document.with(:username,:gender)
  attr :okc, Document.with(:username,:gender)
  
  def relationships
    loves = Loves.current(scope).find '$or' => [{me_id: id},{them_id: id}]
    loves.each{|love| love.swap unless love.me_id == id }
  end
  def fetch_facebook url
    unless url.empty?
      path = "/#{URI.parse(url).path}"
      r = Net::HTTP.get_response('graph.facebook.com',path)
      return self[:fb] = JSON.parse(r.body) if r.code == "200"
    end
    self.delete(:fb)
  end
  def fetch_okcupid url
    unless url.empty?
      data = OKCupid.fetch url
      return self[:okc] = data if data
    end
    self.delete(:okc)
  end
  def name
    return self[:name] if self.name?
    return self.fb.name if self.fb?
    return self.okc.username if self.okc?
    return 'A person'
  end
  def gender?
    self[:gender] or self.fb.gender? or self.okc.gender?
  end
  def gender
    return self[:gender] if self[:gender]
    return self.fb.gender if self.fb.gender?
    return self.okc.gender if self.okc.gender?
    return nil
  end  
  def picture(size=100)
    return self.okc.picture.gsub('160x160',"#{size}x#{size}") if self.okc?
    return "https://graph.facebook.com/#{self.fb[:id]}/picture?width=#{size}&height=#{size}" if self.fb?
    return nil
  end
end

class Loves < CollectionWithScope
  attr :tags, Array
  
  def swap
    self[:me_id],self[:them_id] = self[:them_id],self[:me_id]
  end
  def them
    @them or @them = People.current(scope).with_id(them_id)
  end
  def me
    @me or @me = People.current(scope).with_id(me_id)
  end
end

class Users < Collection
end

class Polycules < Collection
end
