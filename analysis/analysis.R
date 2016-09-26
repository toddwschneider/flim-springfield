library(dplyr)
library(readr)
library(ggplot2)
library(scales)
library(tidytext)
library(lubridate)
library(stringr)
library(extrafont)
library(grid)
library(gridExtra)
library(RPostgreSQL)
source("helpers.R")

words_by_character = query("
  SELECT
    c.id AS character_id,
    c.name,
    c.normalized_name,
    c.gender,
    SUM(s.word_count) AS word_count,
    COUNT(*) AS line_count,
    COUNT(DISTINCT episode_id) AS episode_count
  FROM characters c, script_lines s
  WHERE c.id = s.character_id
    AND s.speaking_line = true
    AND s.word_count > 0
  GROUP BY c.id
  ORDER BY SUM(s.word_count) DESC, c.normalized_name
") %>% mutate(
  name = ifelse(is.na(name_mapping[name]), name, name_mapping[name]),
  name = factor(name, levels = rev(name)),
  gender = factor(gender, levels = c("f", "m"), labels = c("female", "male"))
)

top_10 = ggplot(data = words_by_character[1:10, ], aes(x = name, y = word_count, fill = gender)) +
  geom_bar(stat = "identity") +
  scale_y_continuous("Words spoken, seasons 1-26", labels = unit_format("k", scale = 1e-3)) +
  scale_x_discrete("") +
  scale_fill_manual("", values = c(red, blue)) +
  coord_flip() +
  ggtitle(
    "The Simpsons top characters",
    subtitle = "by number of words spoken, based on scripts from simpsonsworld.com"
  ) +
  theme_tws_simpsons(base_size = 24, grid_width = 0.4) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    plot.title = element_text(size = 48, hjust = 4.4),
    plot.subtitle = element_text(hjust = 1.38, margin = unit(c(0.25, 0.25, 2, 0.25), "line")),
    axis.text.y = element_text(size = 24, margin = unit(c(0, -1, 0, 0), "line")),
    axis.title.y = element_blank(),
    axis.title.x = element_text(size = 40),
    legend.position = "none"
  )
png(filename = "graphs/word_count.png", width = 800, height = 800)
print(top_10)
add_credits(fontsize = 16, ypos = 0.02)
dev.off()

supporting_cast = ggplot(data = words_by_character[5:54, ],
                         aes(x = name, y = word_count, fill = gender)) +
  geom_bar(stat = "identity") +
  scale_y_continuous("Words spoken, seasons 1-26", labels = unit_format("k", scale = 1e-3)) +
  scale_x_discrete("") +
  scale_fill_manual("", values = c(red, blue)) +
  coord_flip() +
  ggtitle(
    "The Simpsons supporting cast",
    subtitle = "by number of words spoken, based on scripts from simpsonsworld.com"
  ) +
  theme_tws_simpsons(base_size = 24, grid_width = 0.4) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    plot.title = element_text(size = 48, hjust = 8.5),
    plot.subtitle = element_text(hjust = 1.38, margin = unit(c(0.25, 0.25, 2, 0.25), "line")),
    axis.text.y = element_text(size = 16, margin = unit(c(0, -1.5, 0, 0), "line")),
    axis.title.y = element_blank(),
    axis.title.x = element_text(size = 40),
    legend.position = "none"
  )
png(filename = "graphs/supporting_cast_word_count.png", width = 800, height = 1600)
print(supporting_cast)
add_credits(fontsize = 16)
dev.off()

words_by_season_and_character = query("
  WITH character_season_word_count AS (
    SELECT
      e.season,
      c.id AS character_id,
      SUM(s.word_count) AS word_count
    FROM episodes e, characters c, script_lines s
    WHERE e.id = s.episode_id
      AND c.id = s.character_id
      AND s.speaking_line = true
      AND s.word_count IS NOT NULL
      AND s.word_count > 0
    GROUP BY e.season, c.id
  ),

  words_by_season AS (
    SELECT season, SUM(word_count) AS word_count
    FROM character_season_word_count
    GROUP BY season
  )

  SELECT
    c.id AS character_id,
    c.name,
    c.normalized_name,
    s.season,
    COALESCE(wc.word_count, 0) AS character_word_count,
    s.word_count AS season_word_count
  FROM characters c
    CROSS JOIN words_by_season s
    LEFT JOIN character_season_word_count wc
      ON c.id = wc.character_id
      AND s.season = wc.season
  ORDER BY c.id, s.season
") %>%
  mutate(season_frac = character_word_count / season_word_count)

for (i in 1:50) {
  char_id = words_by_character$character_id[i]
  char_data = filter(words_by_season_and_character, character_id == char_id)
  fname = paste0("graphs/", str_pad(i, width = 2, pad = "0"), "_", gsub(" ", "_", char_data$normalized_name[1]), ".png")

  p = ggplot(data = char_data, aes(x = season, y = season_frac)) +
    geom_bar(fill = blue, size = 1.5, stat = "identity") +
    scale_x_continuous("Season", breaks = c(1, 5, 10, 15, 20, 25), minor_breaks = NULL) +
    scale_y_continuous(labels = percent) +
    expand_limits(y = 0) +
    ggtitle(char_data$name[1], subtitle = "% of show's total dialogue by season") +
    theme_tws_simpsons(base_size = 36) +
    theme(
      axis.title.y = element_blank(),
      plot.subtitle = element_text(size = rel(0.7))
    )

  png(filename = fname, width = 640, height = 640)
  print(p)
  add_credits(fontsize = 16, ypos = 0.02)
  dev.off()
}

episodes = query("
  SELECT
    id,
    title,
    production_code,
    original_air_date,
    season,
    number_in_season,
    number_in_series,
    us_viewers_in_millions,
    views,
    imdb_rating,
    imdb_votes
  FROM episodes
  WHERE original_air_date < now()
  ORDER BY number_in_series
")

png(filename = "graphs/tv_ratings.png", width = 800, height = 800)
ggplot(data = episodes, aes(x = original_air_date, y = us_viewers_in_millions)) +
  geom_point(color = blue, alpha = 0.8, size = 2) +
  geom_smooth(se = FALSE, color = red, size = 1.5) +
  scale_y_continuous("US viewers", labels = unit_format("m")) +
  scale_x_date("Original air date") +
  ggtitle("The Simpsons TV ratings by episode", subtitle = "based on data from Wikipedia") +
  expand_limits(y = 0) +
  theme_tws_simpsons(base_size = 36) +
  theme(
    plot.title = element_text(hjust = 1.55),
    plot.subtitle = element_text(hjust = -0.72)
  )
add_credits(fontsize = 16, ypos = 0.02)
dev.off()

seasons = episodes %>%
  group_by(season) %>%
  summarize(
    year = min(year(original_air_date)),
    count = n(),
    count_with_ratings = sum(!is.na(us_viewers_in_millions)),
    avg_viewers_in_millions = mean(us_viewers_in_millions, na.rm = TRUE),
    count_with_views = sum(!is.na(views)),
    avg_views = mean(views, na.rm = TRUE),
    count_with_imdb_votes = sum(!is.na(imdb_votes)),
    avg_imdb_votes = mean(imdb_votes, na.rm = TRUE),
    first_episode_date = min(original_air_date),
    last_episode_date = max(original_air_date)
  )

png(filename = "graphs/avg_simpsons_world_views_by_season.png", width = 640, height = 640)
ggplot(data = seasons, aes(x = season, y = avg_views)) +
  geom_bar(stat = "identity", fill = blue) +
  scale_y_continuous(labels = unit_format("k", scale = 1e-3)) +
  scale_x_continuous("Season", breaks = c(1, 5, 10, 15, 20, 25), minor_breaks = NULL) +
  ggtitle("Streaming popularity", subtitle = "average views per episode on simpsonsworld.com") +
  theme_tws_simpsons(base_size = 36) +
  theme(
    axis.title.y = element_blank(),
    plot.title = element_text(hjust = -0.5),
    plot.subtitle = element_text(size = rel(0.7), hjust = 2.7)
  )
add_credits(fontsize = 16, ypos = 0.02)
dev.off()

lines = query("
  SELECT
    s.episode_id,
    e.title,
    e.season,
    c.name AS character,
    c.id AS character_id,
    s.normalized_text AS text
  FROM episodes e, script_lines s, characters c
  WHERE e.id = s.episode_id
    AND c.id = s.character_id
    AND s.speaking_line = true
    AND s.word_count > 0
  ORDER BY s.episode_id, s.number
")

episode_ngrams = lapply(1:5, function(ngram_n) {
  lines %>%
    unnest_tokens(output = word, input = text, token = "ngrams", n = ngram_n) %>%
    count(episode_id, word, sort = TRUE) %>%
    ungroup() %>%
    mutate(ngram_n = ngram_n) %>%
    bind_tf_idf(term_col = word, document_col = episode_id, n_col = n)
}) %>% bind_rows()

episode_summaries_tf_idf = episode_ngrams %>%
  filter(!is.na(tf_idf)) %>%
  arrange(episode_id, desc(tf_idf), desc(ngram_n)) %>%
  group_by(episode_id) %>%
  mutate(num = row_number()) %>%
  ungroup() %>%
  filter(num == 1)

episode_summaries = inner_join(episode_summaries_tf_idf, episodes, by = c("episode_id" = "id")) %>%
  select(title, word, production_code, original_air_date, season, number_in_season, number_in_series, n, ngram_n, tf, idf, tf_idf) %>%
  rename(summary = word)

write_csv(episode_summaries, "data/episode_summaries.csv")

ratings = read_csv("data/nielsen_ratings.csv") %>%
  mutate(year = as.numeric(substr(tv_season, 1, 4)))

avg_by_year = group_by(ratings, year) %>%
  summarize(avg = mean(rating), median = median(rating))

png("graphs/nielsen.png", width = 640, height = 640)
ggplot(data = ratings, aes(x = year, y = rating)) +
  geom_point(alpha = 0.15, size = 2) +
  geom_line(data = avg_by_year, aes(x = year, y = avg), color = blue, size = 2) +
  scale_y_continuous("Nielsen rating") +
  scale_x_continuous("") +
  ggtitle("Top-rated US TV programs by year", subtitle = "Nielsen top 30 rating data via Wikipedia") +
  expand_limits(y = 0) +
  theme_tws_simpsons(base_size = 28) +
  theme(
    axis.title.x = element_text(size = 10),
    text = element_text(family = "Open Sans"),
    plot.title = element_text(hjust = 3.5),
    plot.subtitle = element_text(hjust = -0.25, size = rel(0.7))
  )
add_credits(fontsize = 14, ypos = 0.025, font_family = "Open Sans")
dev.off()

words_by_location = query("
  SELECT
    l.id AS location_id,
    l.name,
    l.normalized_name,
    SUM(s.word_count) AS word_count,
    COUNT(*) AS line_count,
    COUNT(DISTINCT episode_id) AS episode_count
  FROM locations l, script_lines s
  WHERE l.id = s.location_id
    AND s.speaking_line = true
    AND s.word_count > 0
  GROUP BY l.id
  ORDER BY SUM(s.word_count) DESC, l.normalized_name
") %>%
  mutate(name = factor(name, levels = rev(name)))

png(filename = "graphs/words_by_location.png", width = 800, height = 800)
ggplot(data = words_by_location[1:10, ], aes(x = name, y = word_count)) +
  geom_bar(stat = "identity", fill = blue) +
  scale_y_continuous("Words spoken, seasons 1-26", labels = unit_format("k", scale = 1e-3)) +
  scale_x_discrete("") +
  coord_flip() +
  ggtitle(
    "The Simpsons locations",
    subtitle = "by number of words spoken, based on scripts from simpsonsworld.com"
  ) +
  theme_tws_simpsons(base_size = 24, grid_width = 0.4) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    plot.title = element_text(size = 48, hjust = -4.1),
    plot.subtitle = element_text(hjust = 1.38, margin = unit(c(0.25, 0.25, 2, 0.25), "line")),
    axis.text.y = element_text(size = 16, margin = unit(c(0, -1.5, 0, 0), "line")),
    axis.title.y = element_blank(),
    axis.title.x = element_text(size = 40),
    legend.position = "none"
  )
add_credits(fontsize = 16, ypos = 0.02)
dev.off()
