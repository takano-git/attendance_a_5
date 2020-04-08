class AddOvertimeApplyingNoteToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_applying_note, :string
  end
end
