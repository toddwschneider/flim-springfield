class Episode < ActiveRecord::Base
  validates_uniqueness_of :number_in_season, scope: :season
  validates_uniqueness_of :production_code
  validates_presence_of :season, :number_in_series, :number_in_season, :title, :original_air_date, :production_code

  has_many :script_lines, -> { order(:number) }

  WIKIPEDIA_EPISODE_LIST_URLS = [
    "https://en.wikipedia.org/wiki/List_of_The_Simpsons_episodes_(seasons_1%E2%80%9320)",
    "http://en.wikipedia.org/wiki/List_of_The_Simpsons_episodes"
  ]

  def self.set_up_data
    create_episodes
    cache_simpsons_world_views
    cache_imdb_data
    cache_full_htmls_and_scripts
    Character.delay(priority: 10).merge_duplicates!
    Character.delay(priority: 20).set_genders
  end

  def self.create_episodes
    season_number = 1

    WIKIPEDIA_EPISODE_LIST_URLS.each do |url|
      doc = Nokogiri::HTML(RestClient.get(url))

      doc.css("th:contains('Original air date')").each do |e1|
        season_table = e1.parent.parent

        season_table.css("th[id]").each do |e2|
          episode_row = e2.parent

          cells = episode_row.css("th, td")

          viewers = if cells[7].present?
            raw = cells[7].text.gsub(/\[.+\]/i, '').gsub(/n\/a/i, '').gsub(/tbd/i, '')
            raw.to_f if raw.present?
          end

          create! do |ep|
            ep.season = season_number
            ep.number_in_series = cells[0].inner_text.to_i
            ep.number_in_season = cells[1].inner_text.to_i
            ep.title = cells[2].inner_text.sub(/^"/, "").sub(/"$/, "")
            ep.production_code = cells[6].inner_text
            ep.us_viewers_in_millions = viewers

            ep.original_air_date = if cells[6].inner_text == "LABF11"
              "2009-03-22".to_date
            else
              Date.parse(cells[5].inner_text)
            end
          end
        end

        season_number += 1
      end
    end
  end

  def self.cache_simpsons_world_views
    doc = Nokogiri::HTML(RestClient.get('http://www.simpsonsworld.com/heartbeat'))

    doc.css(".season").each do |season_div|
      season_number = season_div['data-season-number'].sub(/^season /i , '').squish.to_i

      season_div.css("li:not(:empty)").each do |episode_li|
        episode_number = episode_li.css(".espisode-number").text.to_i
                                        # "what's that extra 's' for?"
                                        # "that's a typo"

        views = episode_li.css("h4.thumbnail-text").text.split(" ").first.to_i
        truncated_title = episode_li.css("h5.thumbnail-text").text

        image_url = episode_li.css(".thumb img").last.to_h["data-original"].to_s.gsub(/\?.+$/, '')
        video_url = "http://www.simpsonsworld.com#{episode_li.css(".thumb .play-button").first.to_h["href"]}"

        episode = Episode.find_by(season: season_number, number_in_season: episode_number)

        if episode.present?
          episode.views = views
          episode.image_url = image_url
          episode.video_url = video_url
          episode.save!
        end
      end
    end
  end

  def self.cache_imdb_data
    doc = Nokogiri::HTML(RestClient.get('http://www.imdb.com/title/tt0096697/eprate'))

    doc.css("#tn15content table:first tr:not([bgcolor])").each do |row|
      cells = row.css("td")
      season, episode_number = cells.first.text.squish.split(".").map(&:to_i)
      next unless episode = Episode.find_by(season: season, number_in_season: episode_number)

      episode.imdb_rating = cells[2].text.to_f
      episode.imdb_votes = cells[3].text.gsub(',', '').to_i

      episode.save!
    end
  end

  def self.cache_full_htmls_and_scripts
    where.not(video_url: nil).
      find_each(&:cache_full_html_and_script_lines)
  end

  def cache_full_html_and_script_lines
    self.full_html = RestClient.get(video_url)
    save!

    cache_script_lines
    sleep(1)
  end
  handle_asynchronously :cache_full_html_and_script_lines

  def self.cache_script_lines
    select(:id).find_each(&:cache_script_lines)
  end

  def cache_script_lines
    most_recent_timecode = "00:00"
    current_location = nil

    Nokogiri::HTML(full_html).css(".script-item").each_with_index do |script_item, i|
      timecode = script_item.at(".timecode").inner_text

      if timecode.present?
        most_recent_timecode = timecode
      else
        timecode = most_recent_timecode
      end

      timestamp_in_ms = timecode_to_timestamp_in_ms(timecode)

      script_message = script_item.at(".script-message")
      raw_text = script_message.inner_text.squish

      speaking_line = script_message.at("p").children.first.name == "span"

      if speaking_line
        spoken_words = raw_text.
          sub(/^.*?:/, '').
          gsub(/\(.*?\)/, '').
          squish

        character = script_message.
          at("p span").
          inner_text.
          squish.
          chomp(":")
      else
        spoken_words = nil
        character = nil
        current_location = extract_location_from_text(raw_text)
      end

      script_lines.create! do |line|
        line.number = i
        line.raw_text = raw_text
        line.timestamp_in_ms = timestamp_in_ms
        line.speaking_line = speaking_line && spoken_words.present?
        line.raw_character_text = character
        line.raw_location_text = current_location
        line.spoken_words = spoken_words
      end
    end
  end
  handle_asynchronously :cache_script_lines

  def simpsons_archive_url
    "http://www.simpsonsarchive.com/episodes/#{production_code.upcase}.html"
  end

  def self.timecode_to_timestamp_in_ms(timecode)
    if timecode.split(":").length == 2
      timecode = "00:#{timecode}"
    end

    (Time.zone.parse(timecode) - Time.zone.parse("00:00:00")).to_f * 1000
  end
  delegate :timecode_to_timestamp_in_ms, to: "self.class"

  LOCATION_REGEX = %r{^\((.+?):}

  def self.extract_location_from_text(text)
    text[LOCATION_REGEX, 1]
  end
  delegate :extract_location_from_text, to: "self.class"
end
