class AddOfficeIdToOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :office_id, :integer
  end
end
