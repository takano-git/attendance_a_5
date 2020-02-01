class AddAuthorizerToApplies < ActiveRecord::Migration[5.1]
  def change
    add_column :applies, :authorizer, :integer
  end
end
