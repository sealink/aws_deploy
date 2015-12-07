require 'deploy/version'
require 'yaml'
require 'highline'
require 'rugged'
require 'aws-sdk'
require 'deploy/repository'

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

    end

    private

    def self.settings_path
      File.expand_path(File.dirname(__FILE__) + '/../config/settings.yml')
    end
  end
end
