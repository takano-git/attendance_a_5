class AddApplyingChangeAuthorizerIdToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :applying_change_authorizer_id, :integer
  end
end
