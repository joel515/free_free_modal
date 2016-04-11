class ChangeMaterialDefaultValues < ActiveRecord::Migration
  def change
    change_column :materials, :modulus, :float, default: 200000000000.0
    change_column :materials, :modulus_unit, :string, default: "pa"
  end
end
