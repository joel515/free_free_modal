# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160331153710) do

  create_table "jobs", force: :cascade do |t|
    t.string   "pid"
    t.string   "jobdir"
    t.string   "status",      default: "Unsubmitted"
    t.integer  "nodes"
    t.integer  "processors"
    t.string   "name"
    t.integer  "material_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "meshsize",    default: 6
    t.string   "method",      default: "lanb"
    t.integer  "modes"
    t.float    "freqb"
    t.float    "freqe"
    t.string   "geom_file"
    t.string   "geom_units"
  end

  add_index "jobs", ["material_id"], name: "index_jobs_on_material_id"

  create_table "materials", force: :cascade do |t|
    t.string   "name",         default: "Structural Steel"
    t.float    "modulus",      default: 200.0
    t.float    "poisson",      default: 0.3
    t.float    "density",      default: 7850.0
    t.string   "modulus_unit", default: "gpa"
    t.string   "density_unit", default: "kgm3"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

end
