class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :user_name
      t.string :type
      t.string :content
      t.string :current_qid
      t.string :next_qid
      t.timestamps null: false
    end
  end
end
