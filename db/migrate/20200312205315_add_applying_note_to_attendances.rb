class AddApplyingNoteToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :applying_note, :string
  end
end
