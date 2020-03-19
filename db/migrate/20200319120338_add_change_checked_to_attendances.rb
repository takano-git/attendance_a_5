class AddChangeCheckedToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :change_checked, :integer, default: 0
  end
end
