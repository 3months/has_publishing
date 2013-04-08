# HasPublishing

Mark models as `has_publishing` to publish, draft and embargo models. Easy peasy!

[![Build Status](https://travis-ci.org/3months/has_publishing.png?branch=master)](https://travis-ci.org/3months/has_publishing)

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

## A note on publishing

Publishing is typically used in an environment where there may be two installations of the Rails application sharing a common database. This at least is the set up that `has_publishing` is designed to operate in - something like the following:


```
|-- Admin RAILS_ENV=production --| >>>>> SharedDatabase <<<<<< |-- Published Site RAILS_ENV=production_published --|
```

Because of this, the gem applies a default_scope to all instances of this model to either:

* Only return published records if `Rails.env` matches `HasPublishing.config.published_rails_environment`
* Only return draft records otherwise

This prevents 'duplicate' records from appearing for the user (since each 'record' has two representations - 'draft' and 'published/withdrawn')

### So:

1. If you would prefer that this default scope **NOT** be applied, then simply set `HasPublishing.config.scope_records` to `false`. 
2. If you want the default scope to apply properly, ensure that you set the Rails environment of your **published** application in `HasPublishing.config.published_rails_environment`.


## Injecting your own attributes to be saved

When you call ``` publish! ``` and ``` withdraw! ``` you can pass a hash of attributes with it to be updated with your ``` ActiveRecord::Model ``` object. 

This is usefull if you are using a gem like [ancestry](https://github.com/stefankroes/ancestry "ancestry"), for example:

``` ruby
  @page = Page.find_by_slug('foo-bar-page')
  @page.publish!(:parent => (@page.parent.published unless @page.is_root?))
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
