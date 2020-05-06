class AddOvertimeChangeCheckedToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_change_checked, :integer, default: 0

  end
end
