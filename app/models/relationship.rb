class Relationship < ActiveRecord::Base
  attr_accessible :fluidbonded, :kind, :kinky, :married, :note, :sexual, :since, :person_id, :partner_id, :until
  belongs_to :person
  belongs_to :partner, :class_name => 'Person'
  validates_each :person_id do |record, attr, value|
    if value == record.partner_id
      record.errors.add(attr, 'in relationship to self not allowed')
    end
    if record.person.partners_in.map(&:id).include?(record.partner_id)
      record.errors.add(attr, record.person.name + 
        ' can only be listed as in a relationship with the partner from the other direction')
    end
  end
end
