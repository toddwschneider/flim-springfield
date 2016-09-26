class TextNormalizer
  def self.normalize(raw_text)
    raw_text.
      downcase.
      gsub(/\(.*?\)/, '').
      gsub(/\[.*?\]/, '').
      gsub(/[^[[:word:]]\s\-]/, '').
      squish
  end

  def self.remove_possessive_apostrophes(raw_text)
    raw_text.gsub(/'s?(?:\b|$)/i, '')
  end

  def self.remove_apostrophes_and_normalize(raw_text)
    normalize(remove_possessive_apostrophes(raw_text))
  end
end
