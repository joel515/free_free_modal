class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :pid
      t.string :jobdir
      t.string :status, default: "Unsubmitted"
      t.integer :nodes
      t.integer :processors
      t.string :name
      t.references :material, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
