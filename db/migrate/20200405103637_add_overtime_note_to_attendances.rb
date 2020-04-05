class AddOvertimeNoteToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_note, :string
  end
end
