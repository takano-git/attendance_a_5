class AddOvertimeFinishedAtToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_finished_at, :datetime
  end
end
