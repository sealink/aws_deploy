require 'deploy/version'
require 'yaml'
require 'highline'
require 'rugged'
require 'aws-sdk'
require 'deploy/repository'
require 'deploy/configuration'
require 'deploy/eb/state'
require 'deploy/s3/state'
require 'deploy/eb/platform'
require 'deploy/s3/platform'

module Deploy
  class Runner

    def initialize(tag)
      @tag = tag
    end

    def run
      puts "Configured with settings #{settings}"

      if repo.index_modified?
        fail "You have staged changes! Please sort your life out mate, innit?"
      end

      changelog_updated =
        cli.agree "Now hold on there for just a second, partner. "\
                  "Have you updated the changelog ? "

      fail 'Better hop to it then ay?' unless changelog_updated

      # Set up AWS params, i.e. region.
      ::Aws.config.update(region: settings['aws_region'])

      # Pull in and verify our deployment configurations
      puts "Checking available configurations... Please wait..."
      configuration.verify!
      unless configuration.created_folders.empty?
        configuration.created_folders.each do |folder|
          puts "\tCreated #{folder}"
        end
      end
      puts "Check done."
      # Have the user decide what to deploy
      list = apps.map{|app| app.key.sub('/','')}
      puts "Configured applications are:"
      name = cli.choose do |menu|
        menu.prompt = "Choose application to deploy, by index or name."
        menu.choices *list
      end
      app_bucket = apps.detect { |app| app.key == name + '/' }
      puts "Selected \"#{name}\"."

      eb = Eb::State.new(app_bucket)
      s3 = S3::State.new(app_bucket)

      if eb.exists?
        platform = Eb::Platform.new(eb: eb, tag: @tag)
        puts "Environment \'#{name}\' found on EB."
      elsif s3.exists?
        platform = S3::Platform.new(s3: s3, tag: @tag)
        puts "Website \'#{name}\' found on S3."
        puts "Config bucket version \"#{s3.version}\" selected."
      end
      unless platform
        fail "Application given as \'#{name}\'. "\
             "EB environment \'#{name}\' was not found. "\
             "S3 bucket \'#{name}\' was not found either. "\
             "Please fix this before attempting to deploy."
      end

      confirm_launch = cli.agree "Deploy release \'#{@tag}\' to \'#{name}\' ?"
      fail 'Bailing out.' unless confirm_launch
      puts 'Preparing the tagged release version for deployment.'
      repo.prepare!(tag)
      puts 'Deployment commencing.'
      platform.deploy!
      puts "All done."

    end

    private

    def repo
      @repo ||= Repository.new
    end

    def cli
      @cli ||= HighLine.new
    end

    def configuration
      @configuration ||= Configuration.new(settings['config_bucket_name'])
    end

    def apps
      configuration.apps
    end

    def settings
      @settings ||= YAML.load(File.read(settings_path))
    end

    def settings_path
      File.expand_path(File.dirname(__FILE__) + '/../config/settings.yml')
    end
  end
end
