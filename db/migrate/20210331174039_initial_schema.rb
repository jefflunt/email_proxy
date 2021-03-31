class InitialSchema < ActiveRecord::Migration[6.1]
  def change
    create_table :emails, id: :uuid, do |t|
      t.string :provider_id, null: true
      t.string :from_email, null: false
      t.string :from_name, null: false
      t.string :to_email, null: false
      t.string :to_name, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :status, null: false, default: 0
    end
  end
end
