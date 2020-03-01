class AddMarkToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :mark, :integer, default: 0
  end
end
