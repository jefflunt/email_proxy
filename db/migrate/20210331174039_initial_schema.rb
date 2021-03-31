class InitialSchema < ActiveRecord::Migration[6.1]
  def change
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'

    create_table :emails, id: :uuid do |t|
      t.string :provider_id, null: true
      t.string :from, null: false
      t.string :from_name, null: false
      t.string :to, null: false
      t.string :to_name, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :status, null: false, default: 0
      t.text :failure_msg, null: true

      t.timestamps
    end
  end
end
