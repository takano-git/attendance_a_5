class RenameChangedColumnToAttendances < ActiveRecord::Migration[5.1]
  def change
    rename_column :attendances, :changed, :attendance_changed
  end
end
