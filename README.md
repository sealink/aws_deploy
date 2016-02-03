# Deploy AWS

Deploy AWS is a gem for deploying your application code to AWS.
Currently, covered deployment usage scenarios are:
    AWS Elastic Beanstalk applications (via AWS EB CLI)
    AWS S3 hosted web sites (via npm bundle)

## Installation

For multiple application usage, install the gem directly:

```shell
gem install deploy_aws
```

And then execute:

```shell
deploy_aws
```

## Configuration

The gem assumes that your shell includes AWS access keys and region configured.
The gem makes certain assumptions about your S3 folder hierarchy, if S3 is the
deployment target./
Specifically, it expects to find a bucket containing folders that map to your deployable applications.
The application that is to be deployed is then expected to be found in the same named top level S3 bucket.

ElasticBeanstalk applications are deployed directly if detected, and this
configuration is not required.

Example: your S3 bucket named `configs-all` contains your application configurations.
The applications themselves are in S3 buckets.

Then, if you have a static hosted S3 site in the bucket `my-site`,
you'd expect to have a configuration collection in S3 like this:

`configs-all/my-site/config/1.0/somesetting.yml`

`configs-all/my-site/config/2.0/somesetting.yml`

Then, the deployment process will ask you to choose to deploy `my-site`, and the configuration version to be deployed. It will then attempt to find an S3 bucket with the name `my-site`.

## Usage

After installing the gem, execute `deploy_aws` in your deployable project directory.
Follow the interactive prompts.
As per Configuration section, the deployment code makes certain assumptions.
Please consider if they apply to your use case.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Then, run `rake test` or `ruby -Ilib:test test/*` to run the tests. For benchmarked/coloured output, try `ruby -Ilib:test test/* -p`.

To install this gem onto your local machine, run `rake install`. To release a new version, update the version number in `version.rb`, and then run `rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sealink/deploy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
