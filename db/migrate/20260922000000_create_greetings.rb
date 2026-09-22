class CreateGreetings < ActiveRecord::Migration[8.1]
  def up
    create_table :greetings do |t|
      t.string :message, null: false
    end
    execute "INSERT INTO greetings (id, message) VALUES (1, 'hello world')"
    execute "SELECT setval(pg_get_serial_sequence('greetings', 'id'), 1)"
  end

  def down
    drop_table :greetings
  end
end
