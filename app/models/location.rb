class Location < ActiveRecord::Base
  validates_uniqueness_of :name, :normalized_name
  validates_presence_of :name, :normalized_name

  before_validation :set_normalized_name, on: :create

  has_many :script_lines

  def self.find_or_create_by_name(name)
    normalized_name = TextNormalizer.remove_apostrophes_and_normalize(name)

    find_by_normalized_name(normalized_name) ||
      create { |c| c.name = name }
  end

  def set_normalized_name
    self.normalized_name = TextNormalizer.remove_apostrophes_and_normalize(name)
  end
end
