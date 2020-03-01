class AddOvertimeAuthorizerIdToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overtime_authorizer_id, :integer
  end
end
