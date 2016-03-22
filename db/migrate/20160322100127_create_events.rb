class CreateEvents < ActiveRecord::Migration

  def up
    create_table :events do |t|
      t.string :location
      t.date :date

      t.timestamps null: false
    end
  end

  def down
  	drop_table :events
  end

end
