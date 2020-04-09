class AddApplyCountToApplies < ActiveRecord::Migration[5.1]
  def change
    add_column :applies, :apply_count, :integer, default: 0
  end
end
