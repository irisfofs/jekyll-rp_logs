# Jekyll RP Log plugin

## Usage

### Standalone site
First, you're going to need to install Jekyll. [They can explain that better than me.](http://jekyllrb.com/docs/installation/)

#### Basic setup
Clone the repo with `git`. (See the sidebar at right.)

Create a `_config.yml` for the site:

	cp _config.yml.default _config.yml

Then edit it and fill in the needed info for your setup.

**Warning:** Don't tell Jekyll to output to a directory that has anything useful in it -- it deletes anything in the `destination` directory whenever you build the site.

#### Building
Run this command: 
	
	jekyll build

Optionally, add the `--watch` flag to automatically rebuild if you add more logs. Then get the output to somewhere that's served by a webserver, either by setting your `destination` to something there or by copying it manually.

**Warning again:** Destination folders are cleaned whenever Jekyll builds the site. Seriously, don't tell Jekyll to output to a directory that has anything useful in it.

#### Adding RPs
Dump all of them into the root directory of the site (`jekyll-rp-logs`). Right now, only default-format Weechat logs are supported. 

All joins, parts, and quits are stripped, so you don't have to bother pulling those out. All lines that are emotes (`/me`) are RP, and all other lines are OOC by default. Consecutive posts from the same person with timestamps less than a few seconds apart are merged together.

To flag an OOC line as RP, or vice versa, use

* `!RP ` before the timestamp to manually flag the line as RP
* `!OOC ` before the timestamp to manually flag the line as OOC

In order to be picked up and parsed by Jekyll, each file needs a [YAML front matter](http://jekyllrb.com/docs/frontmatter/). One field is required:

* `title` - The name of the RP, as shown on its page and in the index

These are all optional:

* `description` - A short summary that (will eventually be) displayed on the RP page.
* `start_date` - Any valid YAML date, such as `YYYY-MM-DD`. - Displayed on the RP page, and used to sort in the index.
* `canon` - true/false - Whether the RP is considered canonical (whatever that means to you). Sorts RPs into one of two categories in the index.
* `complete` - true/false - Whether the RP is finished, or is still incomplete. Incomplete RPs are flagged as such on the index.
* `format` - What format the logs are in, e.g., `weechat`
* `rp_tags` - YAML list - A list of tags that describe the contents, such as characters involved or events that occur.

You can pretty easily specify more and customize the plugin to your needs.

### As a plugin in an existing Jekyll site
TBD. 