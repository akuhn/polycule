class CreateRelationships < ActiveRecord::Migration
  def change
    create_table :relationships do |t|
      t.integer :source
      t.integer :target
      t.date :since
      t.date :until
      t.string :kind
      t.boolean :married
      t.boolean :fluidbonded
      t.boolean :sexual
      t.boolean :kinky
      t.text :note

      t.timestamps
    end
  end
end
