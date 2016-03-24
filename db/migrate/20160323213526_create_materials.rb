class CreateMaterials < ActiveRecord::Migration
  def change
    create_table :materials do |t|
      t.string :name, default: "Structural Steel"
      t.float :modulus, default: 200.0
      t.float :poisson, default: 0.3
      t.float :density, default: 7850.0
      t.string :modulus_unit, default: "gpa"
      t.string :density_unit, default: "kgm3"

      t.timestamps null: false
    end
  end
end
