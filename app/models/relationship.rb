class Relationship < ActiveRecord::Base
  attr_accessible :fluidbonded, :kind, :kinky, :married, :note, :sexual, :since, :person_id, :partner_id, :until
  belongs_to :person
  belongs_to :partner, :class_name => 'Person'
end
