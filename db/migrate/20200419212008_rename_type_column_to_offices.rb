class RenameTypeColumnToOffices < ActiveRecord::Migration[5.1]
  def change
    rename_column :offices, :type, :office_type
  end
end
