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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131009204026) do

  create_table "telephony_agents", :force => true do |t|
    t.integer  "csr_id",                                                               :null => false
    t.string   "status",                                        :default => "offline"
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
    t.string   "name"
    t.string   "phone_ext"
    t.string   "phone_number"
    t.string   "csr_type"
    t.integer  "timestamp_of_last_presence_event", :limit => 8, :default => 0
    t.string   "phone_type",                                    :default => "phone",   :null => false
    t.string   "sip_number"
    t.string   "call_center_name"
    t.text     "transferable_agents"
    t.boolean  "generate_caller_id",                            :default => false
  end

  add_index "telephony_agents", ["csr_id"], :name => "index_telephony_agents_on_csr_id"
  add_index "telephony_agents", ["status"], :name => "index_telephony_agents_on_status"

  create_table "telephony_blacklisted_numbers", :force => true do |t|
    t.string   "number",     :limit => 10
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "telephony_blacklisted_numbers", ["number"], :name => "index_telephony_blacklisted_numbers_on_number", :unique => true

  create_table "telephony_calls", :force => true do |t|
    t.string   "sid"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "state"
    t.datetime "connected_at"
    t.datetime "terminated_at"
    t.integer  "conversation_id"
    t.integer  "participant_id"
    t.string   "participant_type"
    t.string   "number"
    t.integer  "agent_id"
  end

  add_index "telephony_calls", ["agent_id"], :name => "index_telephony_calls_on_agent_id"
  add_index "telephony_calls", ["conversation_id"], :name => "index_telephony_calls_on_conversation_id"
  add_index "telephony_calls", ["number"], :name => "index_telephony_calls_on_number"
  add_index "telephony_calls", ["sid"], :name => "index_telephony_calls_on_sid"

  create_table "telephony_conversation_events", :force => true do |t|
    t.string   "type"
    t.integer  "conversation_id"
    t.string   "conversation_state"
    t.integer  "call_id"
    t.string   "call_state"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "message_data",       :limit => 2048
  end

  add_index "telephony_conversation_events", ["call_id"], :name => "index_telephony_conversation_events_on_call_id"
  add_index "telephony_conversation_events", ["conversation_id"], :name => "index_telephony_conversation_events_on_conversation_id"

  create_table "telephony_conversations", :force => true do |t|
    t.string   "state"
    t.integer  "loan_id"
    t.string   "transfer_to"
    t.string   "transfer_type"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "transfer_ext"
    t.integer  "transfer_id"
    t.integer  "initiator_id"
    t.string   "transfer_status"
    t.string   "caller_id"
    t.string   "number"
    t.string   "conversation_type", :default => "outbound", :null => false
    t.integer  "transferee_id"
  end

  add_index "telephony_conversations", ["created_at"], :name => "index_telephony_conversations_on_created_at"
  add_index "telephony_conversations", ["loan_id"], :name => "index_telephony_conversations_on_loan_id"
  add_index "telephony_conversations", ["state"], :name => "index_telephony_conversations_on_state"

  create_table "telephony_playable_listeners", :force => true do |t|
    t.integer  "playable_id", :null => false
    t.integer  "csr_id",      :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "telephony_playable_listeners", ["csr_id"], :name => "index_telephony_playable_listeners_on_csr_id"
  add_index "telephony_playable_listeners", ["playable_id"], :name => "index_telephony_playable_listeners_on_playable_id"

  create_table "telephony_playables", :force => true do |t|
    t.integer  "call_id"
    t.string   "url"
    t.datetime "start_time"
    t.integer  "duration"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.string   "type",       :default => "Telephony::Recording"
    t.integer  "csr_id"
  end

  add_index "telephony_playables", ["call_id"], :name => "index_telephony_playables_on_call_id"
  add_index "telephony_playables", ["type"], :name => "index_telephony_recordings_on_type"

end
