class AddApplyingFinishedAtToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :applying_finished_at, :datetime
  end
end
