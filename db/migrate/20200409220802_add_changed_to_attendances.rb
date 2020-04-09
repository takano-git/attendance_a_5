class AddChangedToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :changed, :boolean, default: false
  end
end
