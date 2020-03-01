class AddPreviousStartedAtToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :previous_started_at, :datetime
  end
end
