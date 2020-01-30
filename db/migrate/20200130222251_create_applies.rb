class CreateApplies < ActiveRecord::Migration[5.1]
  def change
    create_table :applies do |t|
      t.date :month
      t.integer :mark, default: 0
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
