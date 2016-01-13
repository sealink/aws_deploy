require 'deploy/version'
require 'yaml'
require 'highline'
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
      log self
      trap_int
      check_for_unstaged_changes!
      check_for_changelog!
      set_aws_region!
      verify_configuration!

      @name       = deployment_target
      @platform   = detect_platform

      request_confirmation!
      synchronize_repo!
      deploy!
    end

    private

    def deploy!
      log 'Deployment commencing.'
      success = @platform.deploy!
      abort "Deployment Failed or timed out. See system output." unless success
      log 'All done.'
    end

    def repo
      @repo ||= Repository.new
    end

    def check_for_unstaged_changes!
      return unless repo.index_modified?
      abort "You have staged changes! Please sort your life out mate, innit?"
    end

    def synchronize_repo!
      log 'Preparing the tagged release version for deployment.'
      repo.prepare!(@tag)
    end

    def cli
      @cli ||= HighLine.new
    end

    def check_for_changelog!
      changelog_updated =
          cli.agree "Now hold on there for just a second, partner. "\
                    "Have you updated the changelog ?"
      abort 'Better hop to it then ay?' unless changelog_updated
    end

    def verify_configuration!
      # Pull in and verify our deployment configurations
      log "Checking available configurations... Please wait..."
      configuration.verify!
      unless configuration.created_folders.empty?
        configuration.created_folders.each do |folder|
          log "\tCreated #{folder}"
        end
      end
      log "Check done."
    end

    def apps_list
      list = apps.map { |app| app.key.sub('/', '') }
    end

    def deployment_target
      selected_app_name(apps_list)
    end

    def selected_app_name(list)
      # Have the user decide what to deploy
      log "Configured applications are:"
      name = cli.choose do |menu|
        menu.prompt = "Choose application to deploy, by index or name."
        menu.choices *list
      end
      log "Selected \"#{name}\"."
      name
    end

    def app_bucket
      apps.detect { |app| app.key == selected_app_name + '/' }
    end

    def set_aws_region!
      # Set up AWS params, i.e. region.
      region = ENV['AWS_REGION'] || settings['aws_region']
      if ENV['AWS_REGION'].empty?
        log "Warning: ENV['AWS_REGION'] is not set, falling back to YML config."
      end
      ::Aws.config.update(region: region)
    end

    def configuration
      @configuration ||= Configuration.new(settings['config_bucket_name'])
    end

    def apps
      configuration.apps
    end

    def eb
      @eb ||= Eb::State.new(@name)
    end

    def s3
      @s3 ||= S3::State.new(@name, app_bucket)
    end

    def detect_platform
      if eb.exists?
        platform = Eb::Platform.new(eb: eb, tag: @tag)
        log "Environment \'#{@name}\' found on EB."
      elsif s3.exists?
        platform = S3::Platform.new(s3: s3, tag: @tag)
        log "Website \'#{@name}\' found on S3."
        log "Config bucket version \"#{s3.version}\" selected."
      end
      unless platform
        abort  "Application given as \'#{@name}\'. "\
               "EB environment \'#{@name}\' was not found. "\
               "S3 bucket \'#{@name}\' was not found either. "\
               "Please fix this before attempting to deploy."
      end
      platform
    end

    def request_confirmation!
      confirm_launch = cli.agree "Deploy release \'#{@tag}\' to \'#{@name}\' ?"
      abort 'Bailing out.' unless confirm_launch
    end

    def settings
      @settings ||= YAML.load(File.read(settings_path))
    end

    def settings_path
      'config/deploy.yml'
    end

    def log(msg)
      # Currently no logging mechanism besides message to stdout
      puts msg
    end

    def trap_int
      Signal.trap('INT') {
        abort "\nGot Ctrl-C, exiting.\n\
        You will have to abort any in-progress deployments manually."
      }
    end

    def to_s
      "Configured with settings: #{settings}"
    end
  end
end
