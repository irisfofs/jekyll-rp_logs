# Jekyll RP Log plugin

## Usage

### Standalone site
First, you're going to need to install Jekyll. [They can explain that better than me.](http://jekyllrb.com/docs/installation/)

#### Basic setup
Clone the repo with `git`.

Create a `_config.yml` for the site:

	cp _config.yml.default _config.yml

Then edit it and fill in the needed info for your setup.

**Warning:** Don't tell Jekyll to output to a directory that has anything useful in it -- it deletes anything in the `destination` directory whenever you build the site.

#### Building
Run `jekyll build`, optionally with the `--watch` flag to automatically rebuild if you add more logs. Then get the output to somewhere that's served by a webserver, either by setting your `destination` to something there or by copying it manually.

#### Adding RPs
Dump all of them into the root directory of the site (`jekyll-rp-logs`).

You can specify some metadata in the [YAML front matter](http://jekyllrb.com/docs/frontmatter/):

* `start_date` - YYYY-MM-DD - Displayed on the RP page.
* `canon` - true/false - Whether the RP is considered canonical (whatever that means to you).
* `complete` - true/false - Whether the RP is finished, or is still incomplete. Incomplete RPs are flagged as such on the index.

### As a plugin in an existing Jekyll site
TBD. 