# Jekyll::RpLogs

[![Build Status](https://travis-ci.org/xiagu/web-character-sheets.svg?branch=master)](https://travis-ci.org/xiagu/web-character-sheets)
[![Test Coverage](https://codeclimate.com/github/xiagu/jekyll-rp_logs/badges/coverage.svg)](https://codeclimate.com/github/xiagu/jekyll-rp_logs/coverage)
[![Code Climate](https://codeclimate.com/github/xiagu/jekyll-rp_logs/badges/gpa.svg)](https://codeclimate.com/github/xiagu/jekyll-rp_logs)
[![Gem Version](https://badge.fury.io/rb/jekyll-rp_logs.svg)](http://badge.fury.io/rb/jekyll-rp_logs)

This plugin provides support for building prettified versions of raw RP logs. Extra noise is stripped out during the building to keep the process as simple as possible: paste in entire log, add title and tags, and go.

The result of building all the test files can be seen here. http://andrew.rs/projects/jekyll-rp_logs/

## Features
* Link to a specific post by its timestamp
* Show and hide OOC chatter at will
* Responsive layout is readable even on phones
* Can be extended to support more log formats via custom parsers (pull requests welcome!)
* Supports multiple formats per file, for those times where you switched IRC clients in the middle of something. Or moved from IRC to Skype, or vice versa.
* Infers characters involved in each RP by the nicks speaking
* Generates a static site that can be hosted anywhere, without needing to run anything more than a web server

## Installation

### Bundler (Recommended)

Install the bundle gem with

    gem install bundle

Create a file named `Gemfile` with the following contents:

```ruby
source 'https://rubygems.org'

group :jekyll_plugins do
  gem "jekyll-rp_logs"
end
```

(If you already have a Gemfile, just add the three group lines instead.)

And then execute:

    bundle

The Gemfile group will tell Jekyll to load the gem, and let you keep it up to date easily with Bundler.

### Manually
Alternatively, install it yourself as:

    gem install jekyll-rp_logs

In this case you'll need to tell Jekyll to load the gem somehow, such as option 2 on the [Installing a plugin](http://jekyllrb.com/docs/plugins/#installing-a-plugin) instructions.

## Usage

### Making a new site

To get started with a new site, create a fresh build directory that will be used to hold the Jekyll input files. Here, all of your raw logs, styling, and templates will be stored.

In this directory, create a file named `Rakefile` and require the gem to get access to its exposed tasks like so:

	echo "require 'jekyll/rp_logs'" > Rakefile

To set up a Jekyll site skeleton in the current directory, execute:

	rake rp_logs:new

This will pull in all the necessary files (SASS, `_includes`, default config, etc) for Jekyll to build the site.

*Important:* To allow Jekyll to actually use the plugin, create a Gemfile as specified above in the [Bundler](#bundler-recommended) section and place it into the build directory.

Edit `_config.yml` and fill in the needed info for your setup.

**Warning:** Don't tell Jekyll to output to a directory that has anything useful in it -- it deletes anything in the `destination` directory whenever you build the site.

Now you should be ready to build!

### Adding RPs
Dump all of the raw logs into the `_rps/` directory of the site.

#### YAML Front Matter
In order to be picked up and parsed by Jekyll, each file needs a [YAML front matter](http://jekyllrb.com/docs/frontmatter/). One field is required:

* `title` - The name of the RP, as shown on its page and in the index

These are all optional (they have default values, configurable in `_config.yml`):

* `start_date` - Any valid YAML date, such as `YYYY-MM-DD`. - Displayed on the RP page, and used to sort in the index. If left blank, will be inferred from the first timestamp.
* `canon` - true/false - Whether the RP is considered canonical (whatever that means to you). Sorts RPs into one of two categories in the index.
* `complete` - true/false - Whether the RP is finished, or is still incomplete. Incomplete RPs are flagged as such on the index.
* `format` - YAML list - What format(s) the logs are in, e.g., `[weechat]`
* `rp_tags` - comma separated list - A list of tags that describe the contents, such as characters involved or events that occur.
* `arc_name` - YAML list - names of story arcs that the RP belongs to

There are also some more options you can toggle:

* `strict_ooc` - true/false - If true, only lines beginning with `(` are considered OOC by default.
* `merge_text_into_rp` - YAML list - A list of nicks whose clients split actions into normal text, like [IRCCloud did for a while](https://twitter.com/XiaguZ/status/590773722593763328).
* `infer_char_tags` - true/false - If false, don't infer the characters in the RP by the nicks who do emotes.

#### Formatting the logs
All joins, parts, and quits are stripped, so you don't have to bother pulling those out. All lines that are emotes (`/me`) are RP, and all other lines are OOC by default. Consecutive posts from the same person with timestamps less than a few seconds apart are merged together.

To flag an OOC line as RP, or vice versa, use

* `!RP ` before the timestamp to manually flag the line as RP
* `!OOC ` before the timestamp to manually flag the line as OOC

To force a line to be merged, or prevent it from being merged, use

* `!MERGE ` before the timestamp to force the line to be merged into the previous one, regardless of the time between them
* `!SPLIT ` before the timestamp to force the line to be kept separate from the previous one, regardless of the time between them

These flags can be combined.

### Building the site
Run this command:

	jekyll build

Optionally, add the `--watch` flag to automatically rebuild if you add more logs. Then get the output to somewhere that's served by a webserver, either by setting your `destination` to something there or by copying it manually.

**Warning again:** Destination folders are cleaned whenever Jekyll builds the site. Seriously, don't tell Jekyll to output to a directory that has anything useful in it.

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `rake install`.

To install the gem and create, then serve a development site to test your changes, run `rake deploy`. This will do a bunch of things:

* Create the `dev_site` directory
* Populate it with a `Gemfile` and `Rakefile` as mentioned in the installation instructions
* Run `bundle` and `rake rp_logs:new`
* Copy test logs from `test/` into the site's `_rps/` directory
* Run `jekyll serve` to build and host the site at `localhost:4000` so you can see it!

## Contributing

1. Fork it ( https://github.com/xiagu/jekyll-rp_logs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
