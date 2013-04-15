class CreateBasics < ActiveRecord::Migration
  def change
    create_table :basics do |t|
      t.text :people
      t.text :relationships

      t.timestamps
    end
  end
end
