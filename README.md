# Jekyll::RpLogs

[![Build Status](https://travis-ci.org/xiagu/jekyll-rp_logs.svg?branch=master)](https://travis-ci.org/xiagu/jekyll-rp_logs)
[![Test Coverage](https://codeclimate.com/github/xiagu/jekyll-rp_logs/badges/coverage.svg)](https://codeclimate.com/github/xiagu/jekyll-rp_logs/coverage)
[![Code Climate](https://codeclimate.com/github/xiagu/jekyll-rp_logs/badges/gpa.svg)](https://codeclimate.com/github/xiagu/jekyll-rp_logs)
[![Gem Version](https://badge.fury.io/rb/jekyll-rp_logs.svg)](http://badge.fury.io/rb/jekyll-rp_logs)

This plugin provides support for building prettified versions of raw RP logs. Extra noise is stripped out during the building to keep the process as simple as possible: paste in entire log, add title and tags, and go.

The result of building all the test files can be seen here: http://andrew.rs/projects/jekyll-rp_logs/ (may be out of date)

## Table of Contents

  * [Features](#features)
  * [Quick Start](#quick-start)
    * [Updating](#updating)
  * [Usage](#usage)
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
* RP descriptions

## Quick Start

Install the gem with

    gem install jekyll-rp_logs

(Installing on Windows will require the [Ruby DevKit](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit) to build some of the dependencies.)

Create a new bare-bones Jekyll site to run the RpLogs plugin from:

    rplogs init path/to/your/new/site

This will create that directory (it aborts if the given directory is not empty) and set up basic scaffold for your site. After the command finishes running, you should have a structure like this:

```
path/to/your/new/site
├── arcs.html
├── _config.yml
├── _config.yml.default
├── css/
│   └── main.scss
├── Gemfile
├── Gemfile.lock
├── _includes/
│   ├── footer.html
│   ├── header.html
│   ├── head.html
│   └── rp.html
├── index.html
├── js/
│   └── toggle_ooc.js
├── _layouts/
│   ├── default.html
│   ├── page.html
│   ├── post.html
│   ├── rp.html
│   └── tag_index.html
├── _rps/
└── _sass/
    ├── _base.scss
    ├── _custom-rules.scss
    ├── _custom-vars.scss
    ├── _layout.scss
    ├── _rp.scss
    └── _syntax-highlighting.scss
```

Edit `_config.yml` and fill in the needed info for your setup.

**Warning:** Don't tell Jekyll to output to a directory that has anything useful in it -- it deletes anything in the `destination` directory whenever you build the site.

Now you should be ready to build!

    bundle exec jekyll build

Building the site should generate an `index.html` in the `destination` directory you configured, along with all the CSS and JS. There won't be any RPs on the index, but it will exist, and have your title and description on it!

### Updating
When a new version of the gem is released, you can update with

    bundle update

If there were any theme updates that you want to install, you'll have to run

    rplogs update

in your site directory. This will overwrite any changes you've made to the default SCSS, includes and index files. `_custom-vars.scss` and `_custom-rules.scss` won't be affected.

## Usage

### Adding RPs
Dump all of the raw logs into the `_rps/` directory of the site. The extension doesn't matter; `.rp` or `.txt` is fine. Don't use `.md` or any other Markdown extension, as that will cause Jekyll to run the file through its Markdown parser (which will take a long time).

#### YAML Front Matter
In order to be picked up and parsed by Jekyll, each file needs a [YAML front matter](http://jekyllrb.com/docs/frontmatter/). One field is required:

* `title` - The name of the RP, as shown on its page and in the index

These are all optional (they have default values, configurable in `_config.yml`):

* `description` - A short description shown under the title on an RP page and while hovering over links on index pages.
* `arc_name` - YAML list - names of story arcs that the RP belongs to
* `canon` - true/false - Whether the RP is considered canonical (whatever that means to you). Sorts RPs into one of two categories in the index.
* `complete` - true/false - Whether the RP is finished, or is still incomplete. Incomplete RPs are flagged as such on the index.
* `format` - YAML list - What format(s) the logs are in, e.g., `[weechat]`
* `rp_tags` - comma separated list - A list of tags that describe the contents, such as characters involved or events that occur.
* `start_date` - Any valid YAML date, such as `YYYY-MM-DD` - Displayed on the RP page, and used to sort in the index. If left blank, will be inferred from the first timestamp.
* `time_line` - Any valid YAML date, such as `YYYY-MM-DD` - Used to change the order an RP in an Arc is stored in while keeping the displayed `start_date` correct. Useful if story RPs were done out of order.

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

    bundle exec jekyll build

Optionally, add the `--watch` flag to automatically rebuild if you add more logs. Then get the output to somewhere that's served by a webserver, either by setting your `destination` to something there or by copying it manually.

**Warning again:** Destination folders are cleaned whenever Jekyll builds the site. Seriously, don't tell Jekyll to output to a directory that has anything useful in it.

### Tag implications and aliases
This feature allows you to set up implications, where something tagged with one tag will automatically be tagged with a list of other tags. The implied tags need to be a list, even if there's only one. These can either be in the main `_config.yml` or `_tags.yml`

Example syntax (for your `_tags.yml`):

```yaml
tag_implications:
  apple: [fruit]
  lorem ipsum: [dolor, sit amet]
```

Tag aliases function just like implications, except the original tag is removed. So they effectively convert one tag into another tag. Or tags.

Example syntax (for your `_tags.yml`):

```yaml
tag_aliases:
  # Keys with a : in them are fine; only a `: ` is parsed as the separator
  char:John_Smith: ["char:John"] # Needs the quotes because of the :
  etaoin: [etaoin shrdlu]
```

The [default tags file](https://github.com/xiagu/jekyll-rp_logs/blob/master/.themes/default/source/_tags.yml.default) has these same examples, demonstrating how and where they should be set.

### Tag descriptions
This feature lets you add a blurb of text on the page for a tag (the one that lists all RPs with that tag).

Example syntax (for your `_tags.yml`):

```yaml
tag_descriptions:
  char:Alice: "Have some words"
  test: "More words"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install the gem onto your local machine, run `rake install`.

To run the tests, run `bundle exec rspec`.
To start [Guard](https://github.com/guard/guard-rspec#readme) and have it run the relevant tests automatically whenever you save a file, run `bundle exec guard`.

To install the gem and create a development site to test your changes, run `rake deploy`. This will do a bunch of things:

* Create the `dev_site/` directory
* Run the same task that `rplogs init` calls, setting up a basic site scaffold
* Copy test logs from `test/` into the site's `_rps/` directory

To additionally serve it at the same time, run `rake serve`, which will:

* Run `rake deploy` and do everything mentioned above
* Run (in `dev_site/`) `bundle exec jekyll serve` to build and host the site at `localhost:4000` so you can see it!

You can of course run `bundle exec jekyll serve` yourself if weird stuff starts happening.

## Contributing

1. Fork it ( https://github.com/xiagu/jekyll-rp_logs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -av`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
