require 'deploy/version'
require 'yaml'
require 'highline'
require 'rugged'
require 'aws-sdk'
require 'deploy/repository'
require 'deploy/configuration'
require 'deploy/eb/state'

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
      list = apps.map{|app| app.key.sub('/','')}
      puts "Configured applications are:"
      name = cli.choose do |menu|
        menu.prompt = "Choose application to deploy, by index or name."
        menu.choices *list
      end
      app_bucket = apps.detect { |app| app.key == name + '/' }
      puts "Selected \"#{name}\"."

      eb = Eb::State.new(app_bucket)
      if eb.exists?
        puts "Environment \'#{name}\' found on EB."
      end

      confirm_launch = cli.agree "Deploy release \'#{tag}\' to \'#{name}\' ?"
      fail 'Bailing out.' unless confirm_launch
      puts 'Preparing the tagged release version for deployment.'
      repo.prepare!(tag)
      puts 'Deployment commencing.'

    end

    private

    def self.settings_path
      File.expand_path(File.dirname(__FILE__) + '/../config/settings.yml')
    end
  end
end
