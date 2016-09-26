class CreateEpisodes < ActiveRecord::Migration
  def change
    create_table :episodes do |t|
      t.string :title, null: false
      t.date :original_air_date, null: false
      t.string :production_code, null: false
      t.integer :season, null: false
      t.integer :number_in_season, null: false
      t.integer :number_in_series, null: false
      t.float :us_viewers_in_millions
      t.integer :views
      t.float :imdb_rating
      t.integer :imdb_votes
      t.string :image_url
      t.string :video_url
      t.text :full_html

      t.timestamps
    end

    add_index :episodes, :production_code, unique: true
    add_index :episodes, [:season, :number_in_season], unique: true
  end
end
