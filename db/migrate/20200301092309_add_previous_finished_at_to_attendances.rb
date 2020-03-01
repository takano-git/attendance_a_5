class AddPreviousFinishedAtToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :previous_finished_at, :datetime
  end
end
