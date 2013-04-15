class Person < ActiveRecord::Base
  attr_accessible :birthday, :city, :country, :email, :facebook, :fetlife, :gender, :house, :name, :nickname, :note, :okcupid, :state, :twitter

  has_many :relationships
  has_many :people, :through => :relationships
  has_many :relationships_in, :class_name => "Relationship", :foreign_key => "partner_id"
  has_many :partners_in, :through => :relationships_in, :source => :person
end
