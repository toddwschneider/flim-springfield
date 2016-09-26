ratings = (1950..2014).each_with_object({}) do |y, h|
  upper = y == 1999 ? "2000" : (y + 1).to_s.last(2)
  url = "https://en.wikipedia.org/wiki/Top-rated_United_States_television_programs_of_#{y}%E2%80%93#{upper}"

  puts url

  table = Nokogiri::HTML(RestClient.get(url)).
    css("#mw-content-text table").
    first

  previous_rank = nil
  previous_network = nil
  previous_rating = nil

  values = table.css("tr").map do |row|
    next unless tds = row.css("td").presence

    has_rank = tds[0].at("a").blank? && tds[0].inner_text.squish =~ /^\d+$/
    title_index = has_rank ? 1 : 0
    has_network = tds.size > 1 && tds[title_index + 1].inner_text.squish !~ /^[\d.,]+$/
    has_rating = tds.size > 1 && tds.last.inner_text.squish =~ /^[\d.,]+$/

    rank = if has_rank
      tds[0].inner_text.squish.to_i
    else
      previous_rank
    end

    title = tds[title_index].inner_text.squish

    network = if has_network
      tds[title_index + 1].inner_text.squish
    else
      previous_network
    end

    rating = if has_rating
      tds.last.inner_text.squish.gsub(",", ".").to_f
    else
      previous_rating
    end

    previous_rank = rank
    previous_network = network
    previous_rating = rating

    [rank, title, network, rating]
  end.compact

  h[y] = values
end

require 'csv'
CSV.open("analysis/data/nielsen_ratings.csv", "wb") do |csv|
  csv << %w(tv_season rank title network rating)

  ratings.each do |y, values|
    values.each do |v|
      csv << ["#{y}–#{y+1}", v].flatten
    end
  end
end
