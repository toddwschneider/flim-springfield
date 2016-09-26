# The Simpsons by the Data

Code in support of this post: [The Simpsons by the Data](http://toddwschneider.com/posts/the-simpsons-by-the-data/)

It's a Rails app, but isn't intended to be run as a server. It processes data from [Simpsons World](http://www.simpsonsworld.com/), [Wikipedia](https://en.wikipedia.org/wiki/List_of_The_Simpsons_episodes), and [IMDb](http://www.imdb.com/title/tt0096697/eprate), and populates a PostgreSQL database called `simpsons_development`. The database contains 4 primary tables: episodes, script_lines, characters, and locations

## Instructions

Assumes you have [Ruby](https://www.ruby-lang.org/en/documentation/installation/) and [PostgreSQL](https://wiki.postgresql.org/wiki/Detailed_installation_guides) installed

```
git clone git@github.com:toddwschneider/flim-springfield.git
cd flim-springfield/
createdb simpsons_development
bundle exec rake db:migrate
bundle exec rake import_data
bundle exec rake jobs:work
```

It takes about 45 minutes to process everything with one worker

## Analysis

R code to analyze the data lives in the `analysis/` folder

## Caveats/areas for improvement

- I deduped some character names when they're printed in different ways, e.g. "TROY" is the same as "Troy McClure", but I certainly did not dedupe all 6000+ characters that appear in the scripts
- Similarly I manually assigned genders to the top 320 or so characters, who collectively account for 86% of the show's dialogue
- I did not dedupe any locations

![tab](https://cloud.githubusercontent.com/assets/70271/18603957/9c00df58-7c44-11e6-8222-6073565db089.png)
