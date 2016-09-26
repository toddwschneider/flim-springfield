class CreateScriptLinesAndCharactersAndLocations < ActiveRecord::Migration
  def change
    create_table :script_lines do |t|
      t.integer :episode_id, null: false
      t.integer :number, null: false
      t.text :raw_text
      t.integer :timestamp_in_ms
      t.boolean :speaking_line, null: false
      t.integer :character_id
      t.integer :location_id
      t.string :raw_character_text
      t.string :raw_location_text
      t.text :spoken_words
      t.text :normalized_text
      t.integer :word_count

      t.timestamps
    end

    add_index :script_lines, [:episode_id, :number], unique: true

    create_table :characters do |t|
      t.string :name, null: false
      t.string :normalized_name, null: false
      t.string :gender

      t.timestamps
    end

    add_index :characters, :name, unique: true
    add_index :characters, :normalized_name, unique: true

    create_table :locations do |t|
      t.string :name, null: false
      t.string :normalized_name, null: false

      t.timestamps
    end

    add_index :locations, :name, unique: true
    add_index :locations, :normalized_name, unique: true
  end
end
