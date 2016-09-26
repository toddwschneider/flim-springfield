class ScriptLine < ActiveRecord::Base
  validates_presence_of :episode_id, :number
  validates_uniqueness_of :number, scope: :episode_id
  validates_inclusion_of :speaking_line, in: [true, false]

  belongs_to :episode
  belongs_to :character
  belongs_to :location

  before_create :set_character, :set_location, :set_normalized_text_and_word_count

  scope :speaking, -> { where(speaking_line: true) }

  def set_character
    return unless raw_character_text.present?
    self.character = Character.find_or_create_by_name(raw_character_text)
  end

  def set_location
    return unless raw_location_text.present?
    self.location = Location.find_or_create_by_name(raw_location_text)
  end

  def set_normalized_text_and_word_count
    return unless speaking_line?

    self.normalized_text = TextNormalizer.normalize(spoken_words.to_s)
    self.word_count = normalized_text.split(" ").size
  end
end
