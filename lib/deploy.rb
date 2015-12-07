require 'deploy/version'
require 'yaml'
require 'highline'
require 'rugged'
require 'aws-sdk'
require 'deploy/repository'
require 'deploy/configuration'

module Deploy
  class Deployment
    def self.settings
      @settings ||= YAML.load(File.read(settings_path))
    end

    def self.deploy(tag)
      puts "Configured with settings #{settings}"

      repo = Repository.new
      if repo.index_modified?
        fail "You have staged changes! Please sort your life out mate, innit?"
      end

      cli = HighLine.new
      changelog_updated =
        cli.agree "Now hold on there for just a second, partner. "\
                  "Have you updated the changelog ? "

      fail 'Better hop to it then ay?' unless changelog_updated

      # Set up AWS params, i.e. region.
      ::Aws.config.update(region: settings['aws_region'])

      # Pull in and verify our deployment configurations
      configuration = Configuration.new(settings['config_bucket_name'])
      puts "Checking available configurations... Please wait..."
      configuration.verify!
      unless configuration.created_folders.empty?
        configuration.created_folders.each do |folder|
          puts "\tCreated #{folder}"
        end
      end
      puts "Check done."
      # Have the user decide what to deploy
      apps = configuration.apps
      app_names = apps.map(&:key)
      puts "Found applications. Select index of the one to deploy:"
      longest_key = app_names.max_by(&:length)
      app_names.each_with_index do |app, index|
        printf "%-#{longest_key.length}s %s\n", app.sub('/',''), index
      end
      app_index = Integer(STDIN.gets)
      app_bucket = apps.detect { |app| app.key == app_names[app_index] }
      name = app_bucket.key.sub('/','')
      puts "App configuration \"#{name}\" selected."

    end

    private

    def self.settings_path
      File.expand_path(File.dirname(__FILE__) + '/../config/settings.yml')
    end
  end
end
