class AddChangeTomorrowToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :change_tomorrow, :integer, default: 0
  end
end
