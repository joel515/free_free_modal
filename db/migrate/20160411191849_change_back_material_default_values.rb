class ChangeBackMaterialDefaultValues < ActiveRecord::Migration
  def change
    change_column :materials, :modulus, :float, default: 200.0
    change_column :materials, :modulus_unit, :string, default: "gpa"
  end
end
