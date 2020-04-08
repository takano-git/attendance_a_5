class AddOvertimeApplyingFinishedAtToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_applying_finished_at, :datetime
  end
end
