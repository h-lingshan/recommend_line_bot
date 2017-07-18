class Add < ActiveRecord::Migration
  def change
    add_column :Stores, :address, :string
  end
end
