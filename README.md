# UnchartedCode Ember::Schema

Generates a json schema for jasonapi resource models

## Installation

Add this line to your application's Gemfile:

    gem 'ember-schema'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ember-schema

## Usage

The schema will automatically be generated when you run db:migrate

```
rake db:migrate
```

and it will show up in db/schema.js. You can also fire it off manually like this

```
rake db:schema:ember
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ember-schema/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
