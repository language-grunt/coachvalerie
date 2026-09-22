require "json"

class CreateReferencePages < ActiveRecord::Migration[8.1]
  def up
    create_table :reference_pages do |t|
      t.string :path, null: false
      t.jsonb :fields, null: false, default: {}
      t.timestamps
    end
    add_index :reference_pages, :path, unique: true
    # Initial import only. Later deploys must never overwrite editorial changes.
    importer = Class.new(ActiveRecord::Base) { self.table_name = "reference_pages" }
    Dir[Rails.root.join("replica/content/*.json")].sort.each do |file|
      data = JSON.parse(File.read(file))
      importer.create!(path: data.fetch("path"), fields: data.fetch("fields"))
    end
  end

  def down
    drop_table :reference_pages
  end
end
