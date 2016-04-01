class AddGeometryToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :geom_file, :string
    add_column :jobs, :geom_units, :string
  end
end
