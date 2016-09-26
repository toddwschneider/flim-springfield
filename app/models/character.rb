class Character < ActiveRecord::Base
  validates_uniqueness_of :name, :normalized_name
  validates_presence_of :name, :normalized_name
  validates_inclusion_of :gender, in: %w(m f), allow_nil: true

  before_validation :set_normalized_name, on: :create

  has_many :script_lines

  def self.find_or_create_by_name(name)
    normalized_name = TextNormalizer.normalize(name)

    find_by_normalized_name(normalized_name) ||
      create { |c| c.name = name }
  end

  def set_normalized_name
    self.normalized_name = TextNormalizer.normalize(name)
  end

  CHARACTER_NAMES_TO_MERGE = {
    "troy" => "troy mcclure",
    "krabappel" => "edna krabappel-flanders",
    "brockman" => "kent brockman",
    "roger myers jr" => "roger meyers jr",
    "meyers" => "roger meyers jr",
    "mcbain" => "rainier wolfcastle",
    "wolfcastle" => "rainier wolfcastle",
    "bleeding gums" => "bleeding gums murphy",
    "g k willington" => "groundskeeper willie",
    "young homer" => "homer simpson",
    "young grampa" => "grampa simpson",
    "young marge" => "marge simpson",
    "young burns" => "c montgomery burns",
    "young krusty" => "krusty the clown",
    "teenage homer" => "homer simpson",
    "teenage marge" => "marge simpson",
    "teenage bart" => "bart simpson",
    "teenage lisa" => "lisa simpson",
    "teenage milhouse" => "milhouse van houten",
    "adult bart" => "bart simpson",
    "adult lisa" => "lisa simpson",
    "homers brain" => "homer simpson",
    "homers thoughts" => "homer simpson",
    "marges thoughts" => "marge simpson",
    "barts thoughts" => "bart simpson",
    "lisas thoughts" => "lisa simpson",
    "kirk voice milhouse" => "milhouse van houten"
  }

  def self.merge_duplicates!
    CHARACTER_NAMES_TO_MERGE.each do |wrong_name, correct_name|
      next unless to_be_destroyed = find_by(normalized_name: wrong_name)
      to_be_destroyed.merge_into!(find_by(normalized_name: correct_name))
    end
  end

  def merge_into!(other_character)
    script_lines.update_all(character_id: other_character.id)
    destroy
  end

  def self.set_genders
    require 'csv'

    CSV.foreach("#{Rails.root}/analysis/data/character_genders.csv", headers: true) do |row|
      c = find_by(normalized_name: row["normalized_name"])
      c.gender = row["gender"]
      c.save!
    end
  end
end
