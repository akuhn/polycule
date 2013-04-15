class RenameRelationshipSource < ActiveRecord::Migration
  def change
    change_table :relationships do |t|
      t.rename :source, :person_id
      t.rename :target, :partner_id
    end
  end
end
