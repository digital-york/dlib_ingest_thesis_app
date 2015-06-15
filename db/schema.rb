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

ActiveRecord::Schema.define(version: 20150522141148) do

  create_table "ingests", force: :cascade do |t|
    t.string   "folder"
    t.string   "file"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "content"
    t.string   "rights"
    t.string   "worktype"
    t.string   "filestore"
    t.string   "repository"
    t.string   "parent"
    t.string   "photographer"
  end

  create_table "theses", force: :cascade do |t|
    t.string   "name"
    t.string   "title"
    t.string   "date"
    t.text     "abstract"
    t.string   "degreetype"
    t.string   "supervisor"
    t.string   "department"
    t.string   "subjectkeyword"
    t.string   "rightsholder"
    t.string   "licence"
    t.string   "uf_uid"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "uploaded_files", force: :cascade do |t|
    t.string   "file_uid"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "thesis_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",               default: "", null: false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "surname"
    t.string   "givenname"
    t.string   "degreetype"
    t.string   "supervisor"
    t.string   "department"
  end

  add_index "users", ["login"], name: "index_users_on_login", unique: true

end
