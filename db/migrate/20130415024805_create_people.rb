class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name
      t.string :nickname
      t.string :gender
      t.date :birthday
      t.string :house
      t.string :city
      t.string :state
      t.string :country
      t.string :email
      t.string :twitter
      t.string :facebook
      t.string :okcupid
      t.string :fetlife
      t.text :note

      t.timestamps
    end
  end
end
