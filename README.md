# Deploy

Deploy is a gem for deploying your application code.
The target is an upstream provider that allows you to tag your release, and upload the app.
Currently, covered deployment usage scenarios are:
    AWS Elastic Beanstalk applications (via AWS EB CLI)
    AWS S3 hosted web sites (via npm bundle)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'deploy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deploy

## Configuration

Configure `config/settings.yml` for your environment.
The gem makes certain assumptions about your S3 folder hierarchy.
Specifically, it expects to find a bucket containing folders that map to your deployable applications.
The application that is to be deployed is then expected to exist in the same named EB environment.
Otherwise, it is expected to be found in the same named top level S3 bucket.

Example: your S3 bucket named `configs-all` contains your application configurations.
The applications themselves are either in ElasticBeanstalk or in S3 buckets.

Then, if you have a static hosted S3 site in the bucket `my-site`, and an
 EB application named `my-app` with environments `my-app` and `my-app-test`,
you'd expect to have a configuration collection in S3 like this:

`configs-all/my-app/config/1.0/somesetting.yml`

`configs-all/my-app/config/2.0/somesetting.yml`

`configs-all/my-app-test/config/1.0/somesetting.yml`

`configs-all/my-app-test/config/2.0/somesetting.yml`

`configs-all/my-site/config/1.0/somesetting.yml`

`configs-all/my-site/config/2.0/somesetting.yml`

And, the deployment process will ask you to choose to deploy `my-site`, or `my-app-test` or `my-app`.
If you chose `my-site`, it will then attempt to find an ElasticBeanstalk environment or an S3 bucket with the name `my-site`.

## Usage

After installing the gem, invoke `bin/deploy` in your deployable project directory.
Follow the interactive prompts.
As per Configuration section, the deployment code makes certain assumptions.
Please consider if they apply to your use case.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Then, run `rake test` or `ruby -Ilib:test test/*` to run the tests. For benchmarked/coloured output, try `ruby -Ilib:test test/* -p`.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/deploy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
