con = dbConnect(dbDriver("PostgreSQL"), dbname = "simpsons_development", host = "localhost")
query = function(sql) { tbl_df(fetch(dbSendQuery(con, sql), n = 1e8)) }

# http://springfieldfiles.com/index.php?jump=colours
yellow = "#ffd90f"
blue = "#4f76df"
light_blue = "#70d1ff"
orange = "#ff850c"
red = "#da6901"
green = "#83c33f"

theme_tws_simpsons = function(base_size = 12, grid_width = 0.2) {
  bg_rect = element_rect(fill = yellow, color = yellow)

  theme_bw(base_size) +
    theme(text = element_text(family = "Akbar"),
          plot.background = bg_rect,
          legend.background = bg_rect,
          panel.background = bg_rect,
          panel.grid.major = element_line(colour = light_blue, size = grid_width),
          panel.grid.minor = element_line(colour = light_blue, size = grid_width),
          legend.key.width = unit(1.5, "line"),
          legend.key = element_blank(),
          axis.title.x = element_text(margin = unit(c(0.5, 0.25, 0.5, 0.25), "line")),
          axis.title.y = element_text(margin = unit(c(0, 1, 0, 0.1), "line")),
          axis.ticks = element_blank(),
          panel.border = element_blank())
}

add_credits = function(fontsize = 12, color = "#222222", xpos = 0.99, ypos = 0.01, font_family = "Akbar") {
  grid.text("toddwschneider.com",
            x = xpos,
            y = ypos,
            just = "right",
            gp = gpar(fontsize = fontsize,
                      fontfamily = font_family,
                      col = color))
}

name_mapping = c(
  "Homer Simpson" = "Homer",
  "Marge Simpson" = "Marge",
  "Bart Simpson" = "Bart",
  "Lisa Simpson" = "Lisa",
  "C. Montgomery Burns" = "Mr. Burns",
  "Milhouse Van Houten" = "Milhouse",
  "Apu Nahasapeemapetilon" = "Apu",
  "Lenny Leonard" = "Lenny",
  "Edna Krabappel-Flanders" = "Mrs. Krabappel",
  "Carl Carlson" = "Carl",
  "Rev. Timothy Lovejoy" = "Rev. Lovejoy",
  "Mayor Joe Quimby" = "Mayor Quimby",
  "Professor Jonathan Frink" = "Professor Frink",
  "Kearney Zzyzwicz" = "Kearney",
  "HERB" = "Herb Simpson",
  "DOLPH" = "Dolph",
  "Captain Horatio McCallister" = "Captain McCallister"
)
