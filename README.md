# Jekyll::RpLogs

[![Build Status](https://travis-ci.org/xiagu/web-character-sheets.svg?branch=master)](https://travis-ci.org/xiagu/web-character-sheets)
[![Test Coverage](https://codeclimate.com/github/xiagu/jekyll-rp_logs/badges/coverage.svg)](https://codeclimate.com/github/xiagu/jekyll-rp_logs/coverage)
[![Code Climate](https://codeclimate.com/github/xiagu/jekyll-rp_logs/badges/gpa.svg)](https://codeclimate.com/github/xiagu/jekyll-rp_logs)
[![Gem Version](https://badge.fury.io/rb/jekyll-rp_logs.svg)](http://badge.fury.io/rb/jekyll-rp_logs)

This plugin provides support for building prettified versions of raw RP logs. Extra noise is stripped out during the building to keep the process as simple as possible: paste in entire log, add title and tags, and go.

The result of building all the test files can be seen here. http://andrew.rs/projects/jekyll-rp_logs/

## Table of Contents

  * [Features](#features)
  * [Installation](#installation)
    * [Bundler (Recommended)](#bundler-recommended)
    * [Manually](#manually)
    * [Updating](#updating)
  * [Usage](#usage)
    * [Making a new site](#making-a-new-site)
    * [Adding RPs](#adding-rps)
      * [YAML Front Matter](#yaml-front-matter)
      * [Formatting the logs](#formatting-the-logs)
    * [Building the site](#building-the-site)
    * [Tag implications and aliases](#tag-implications-and-aliases)
    * [Tag descriptions](#tag-descriptions)
  * [Development](#development)
  * [Contributing](#contributing)

## Features
* Link to a specific post by its timestamp
* Show and hide OOC chatter at will
* Responsive layout is readable even on phones
* Can be extended to support more log formats via custom parsers (pull requests welcome!)
* Supports multiple formats per file, for those times where you switched IRC clients in the middle of something. Or moved from IRC to Skype, or vice versa.
* Infers characters involved in each RP by the nicks speaking
* Generates a static site that can be hosted anywhere, without needing to run anything more than a web server
* Tagging and a tag implication/alias system
* Tag descriptions

## Installation

If you are interested in developing this gem, skip down to the [Development](#development) section instead. This section is for setting up a site that uses the gem.

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

### Updating
When a new version of the gem is released, you can update with

    bundle update

If there were any theme updates that you want to install, you'll have to run

    rake rp_logs:new

again too. This will overwrite any changes you've made to the default SCSS, includes and index files. `_custom-vars.scss` and `_custom-rules.scss` won't be affected.

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

* `arc_name` - YAML list - names of story arcs that the RP belongs to
* `canon` - true/false - Whether the RP is considered canonical (whatever that means to you). Sorts RPs into one of two categories in the index.
* `complete` - true/false - Whether the RP is finished, or is still incomplete. Incomplete RPs are flagged as such on the index.
* `format` - YAML list - What format(s) the logs are in, e.g., `[weechat]`
* `rp_tags` - comma separated list - A list of tags that describe the contents, such as characters involved or events that occur.
* `start_date` - Any valid YAML date, such as `YYYY-MM-DD`. - Displayed on the RP page, and used to sort in the index. If left blank, will be inferred from the first timestamp.
* `time_line` - Used to change the order an RP in an Arc is stored in while keeping the displayed start_date correct. Useful if story RPs were done out of order. Must be a valid YAML date, such as `YYYY-MM-DD`. -

There are also some more options you can toggle. Some are needed for giving the parser more information about oddities in posts, so that it can merge split posts correctly.

* `infer_char_tags` - true/false - If false, don't infer the characters in the RP by the nicks who do emotes.
* `merge_text_into_rp` - YAML list - A list of nicks whose clients split actions into normal text, like [IRCCloud did for a while](https://twitter.com/XiaguZ/status/590773722593763328).
* `splits_by_character` - YAML list - A list of nicks whose clients split posts by characters and not by words. (For example, splitting "hello" into "hel" "lo".)
* `strict_ooc` - true/false - If true, only lines beginning with `(` are considered OOC by default.

#### Formatting the logs
The goal of this plugin is to make updating logs as easy and painless as possible. The goal is to be able to paste a log in, add trivial metadata at the top, and be good to go. Here's everything the plugin does for you so you don't have to:
* All joins, parts, and quits are stripped, so you don't have to bother pulling those out
* All lines that are emotes (`/me`) are interpreted as RP, and all other lines are OOC by default
* Lines starting with `(` or `[` are interpreted as OOC, even if they're an emote. (These characters are configurable in `_config.yml`.)
* Consecutive posts from the same person with timestamps less than or equal to 3 seconds apart are merged together. (The exact amount of time is configurable in `_config.yml`.)

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

### Tag implications and aliases
This feature allows you to set up implications, where something tagged with one tag will automatically be tagged with a list of other tags. The implied tags need to be a list, even if there's only one.

Example syntax (for your `_config.yml`):

```yaml
tag_implications:
  apple: [fruit]
  lorem ipsum: [dolor, sit amet]
```

Tag aliases function just like implications, except the original tag is removed. So they effectively convert one tag into another tag. Or tags.

Example syntax (for your `_config.yml`):

```yaml
tag_aliases:
  # Keys with a : in them are fine; only a `: ` is parsed as the separator
  char:John_Smith: ["char:John"] # Needs the quotes because of the :
  etaoin: [etaoin shrdlu]
```

The [default config file](https://github.com/xiagu/jekyll-rp_logs/blob/1247e4d2cacd7a1cb658828d286bbae049ce2e13/.themes/default/source/_config.yml.default#L41) has these same examples, demonstrating how and where they should be set.

### Tag descriptions
This feature lets you add a blurb of text on the page for a tag (the one that lists all RPs with that tag).

Example syntax (for your `_config.yml`):

```yaml
tag_descriptions:
  char:Alice: "Have some words"
  test: "More words"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `rake install`.

To install the gem and create, then serve a development site to test your changes, run `rake serve`. This will do a bunch of things:

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
