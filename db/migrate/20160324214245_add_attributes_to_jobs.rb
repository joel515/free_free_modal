class AddAttributesToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :meshsize, :integer, default: 6
    add_column :jobs, :method, :string, default: "lanb"
    add_column :jobs, :modes, :integer
    add_column :jobs, :freqb, :float
    add_column :jobs, :freqe, :float
  end
end
