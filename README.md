[![Gem Version](https://badge.fury.io/rb/rev-api.png)](http://badge.fury.io/rb/rev-api)
[![Build Status](https://secure.travis-ci.org/revdotcom/rev-ruby-sdk.png?branch=master)](https://secure.travis-ci.org/revdotcom/rev-ruby-sdk)
[![Dependency Status](https://gemnasium.com/revdotcom/rev-ruby-sdk.png?travis)](https://gemnasium.com/revdotcom/rev-ruby-sdk)
[![Code Climate](https://codeclimate.com/github/revdotcom/rev-ruby-sdk.png)](https://codeclimate.com/github/revdotcom/rev-ruby-sdk)

[Reference](https://www.rev.com/api/docs) | [RDocs](http://rubydoc.info/github/revdotcom/rev-ruby-sdk/master/frames)

rev-ruby-sdk
------------

### Background

Rev.com provides transcription, caption and translation services powered by humans. The Rev.com API allows you to tap transcription
and caption services with no manual steps. It's a RESTful API, documented at <https://www.rev.com/api/docs>.

The Ruby SDK for the Rev API provides a convenient Ruby wrapper for the Rev.com API. All operations of the API, as described
at <https://www.rev.com/api/operations>, are supported.

### Install

```shell
gem install rev-api
```

or put it into your Gemfile.

When you need it:

```ruby
require 'rev-api'
```

### Authentication

If you are building a new API client, you must first obtain a client API key, which you can do at <https://www.rev.com/api>.

All operations in the API are performed on behalf of a Rev customer, identified by their user API key. The client key / user
key pair is used to authenticate each API operation. Once you have the two keys, you can create a new Rev.com API client:


```ruby
require 'rev-api'

rev_client = Rev.new('your_client_key', 'your_user_key')
```

You can read more about authentication in the Rev.com API at <https://www.rev.com/api/security>

### Sandbox

All operations can be executed against either the production or the sandbox environment. The sandbox environment allows you
to test your API client without actually paying for orders and having them worked on.

By default, the Rev.com API client executes against the production environment. To go against the sandbox instead,
initialize the client this way:

```ruby
require 'rev-api'

rev_client = Rev.new('your_client_key', 'your_user_key', Rev::Api::SANDBOX_HOST)
```

### Usage

The snippets below assume you've initialized `rev_client`:

```ruby
rev_client = Rev.new('your_client_key', 'your_user_key')
```

#### Listing orders

```ruby
orders_page = rev_client.get_orders_page(1) # get a single page of orders
all_orders = rev_client.get_all_orders # get first page of orders history
orders_by_client_ref = rev_client.get_orders_by_client_ref('some_ref') # get orders with reference id of 'some_ref'
```

#### Get a single order by order number

```ruby
some_order = rev_client.get_order('TCxxxxxxxx')
puts "Original comment: #{some_order.comments.first.text}"
```

#### Cancel an order given an order number

```ruby
rev_client.cancel_order('TCxxxxxxxx')
```

#### Print out the text of all transcripts in an order

```ruby
order = rev_client.get_order('TCxxxxxxx')

order.transcripts.each do |t|
	puts rev_client.get_attachment_content_as_string t.id
	puts
end
```

Refer to `cli.rb` in the `examples` directory for a full example illustrating placing orders, handling error responses, etc.

### Documentation

[YARD documentation](http://rubydoc.info/github/revdotcom/rev-ruby-sdk/master/frames) can be generated locally by running `rake yard` command, and will be placed in the `doc` directory.

You can find API documentation at <https://www.rev.com/api/docs>.

### Support

If you have any questions or suggestions for improvement, email us directly at api[at]rev[dot]com.

### Compatibility

- MRI 2.0.0

### Tests

Minitest suite might be run using `rake test` command.
Current stack:

- minitest
- webmock
- vcr
- turn

### Dependencies

- httparty
