class CreateStores < ActiveRecord::Migration
  def change
    create_table :stores do |t|
      t.float :latitude
      t.float :longitude

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :stores
  end
end
