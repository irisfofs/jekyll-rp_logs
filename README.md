# Jekyll::RpLogs

## Installation

### Bundler
Add these lines to your application's Gemfile:

```ruby
group :jekyll_plugins do
  gem 'jekyll-rp_logs'
end
```
And then execute:

    $ bundle

The Gemfile group will tell Jekyll to load the gem, and let you keep it up to date easily with Bundler.

### Manually
Alternatively, install it yourself as:

    $ gem install jekyll-rp_logs

In this case you'll need to tell Jekyll to load the gem somehow, such as option 2 on the [Installing a plugin](http://jekyllrb.com/docs/plugins/#installing-a-plugin) instructions.

## Usage

### Making a new site
Require the gem in your Rakefile to get access to its exposed tasks:

	echo "require 'jekyll/rp_logs'" >> Rakefile

To set up a new site in the current directory, execute:

	rake rp_logs:new

Then edit `_config.yml` and fill in the needed info for your setup.

**Warning:** Don't tell Jekyll to output to a directory that has anything useful in it -- it deletes anything in the `destination` directory whenever you build the site.

### Building the site
Run this command: 
	
	jekyll build

Optionally, add the `--watch` flag to automatically rebuild if you add more logs. Then get the output to somewhere that's served by a webserver, either by setting your `destination` to something there or by copying it manually.

**Warning again:** Destination folders are cleaned whenever Jekyll builds the site. Seriously, don't tell Jekyll to output to a directory that has anything useful in it.

### Adding RPs
Dump all of them into the `_rps/` directory of the site.

All joins, parts, and quits are stripped, so you don't have to bother pulling those out. All lines that are emotes (`/me`) are RP, and all other lines are OOC by default. Consecutive posts from the same person with timestamps less than a few seconds apart are merged together.

To flag an OOC line as RP, or vice versa, use

* `!RP ` before the timestamp to manually flag the line as RP
* `!OOC ` before the timestamp to manually flag the line as OOC

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/jekyll-rp_logs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
