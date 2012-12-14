# HasPublishing

Mark models as `has_publishing` to publish, draft and embargo models. Easy peasy!

## Features

* `published`, `draft`, `embargoed` scopes for easy filtering/finding
* Rails environment-based default scoping: if your site is using `production`, draft/embargoed records will still be found - if you use `RAILS_ENV=production_published`, though, only published records will be found.
* In use in production on multiple sites
* Covered by automated tests

## Installation

Add this line to your application's Gemfile:

    gem 'has_publishing'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install has_publishing

## Usage

Simply add `has_publishing` to the model of your choice, and then generate the publishing attributes for your model:

``` bash
bundle exec rails generate migration [YOUR MODEL NAME] embargoed_until:datetime published_at:datetime published_id:integer kind:string
```

…and then of course run `rake db:migrate`

(If anyone would like to add a generator to automate this process, it would be very much appreciated)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
