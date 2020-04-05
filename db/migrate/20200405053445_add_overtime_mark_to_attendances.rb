class AddOvertimeMarkToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_mark, :integer, default: 0
  end
end
