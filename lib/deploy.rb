require 'deploy/version'
require 'yaml'
require 'highline'
require 'aws-sdk'
require 'deploy/repository'
require 'deploy/s3/configuration'
require 'deploy/eb/state'
require 'deploy/s3/state'
require 'deploy/eb/platform'
require 'deploy/iam/client'
require 'deploy/s3/platform'
require 'deploy/eb/application'
require 'deploy/error_handler'

module Deploy
  class Runner
    EB_INTERNALS=%w(docker/ resources/)

    def initialize(tag)
      @tag = tag
    end

    def run
      validate!
      perform!
    end

    private

    def validate!
      trap_int
      check_for_unstaged_changes!
      check_for_changelog!
      check_for_aws_access!
    end

    def perform!
      fetch_eb
      configure!

      @name       = deployment_target
      @platform   = detect_platform

      request_confirmation!
      synchronize_repo!
      deploy!
    end

    def log(msg)
      # Currently no logging mechanism besides message to stdout
      puts msg
    end

    def settings
      @settings ||= YAML.load(File.read(settings_path))
    end

    def settings_path
      'config/deploy.yml'
    end

    def trap_int
      Signal.trap('INT') {
        abort "\nGot Ctrl-C, exiting.\n\
        You will have to abort any in-progress deployments manually."
      }
    end

    def check_for_unstaged_changes!
      return unless repo.index_modified?
      abort "You have staged changes! Please sort your life out mate, innit?"
    end

    def check_for_changelog!
      changelog_updated =
          cli.agree "Now hold on there for just a second, partner. "\
                    "Have you updated the changelog ?"
      abort 'Better hop to it then ay?' unless changelog_updated
    end

    def check_for_aws_access!
      # Verify up AWS params, i.e. that we have access key and region.
      # Do so by connecting to IAM directly
      # Why IAM? If your user doesn't exist, nothing else will work.
      user =  IAM::Client.connection
      log "You are connected as #{user}."
    end

    def fetch_eb
      @fetch_eb = configuration_source if @fetch_eb.nil?
      @fetch_eb
    end

    def configuration_source
      return false unless Eb::Platform.configured?
      log 'Elastic Beanstalk configuration detected locally.'
      bucket = settings['elasticbeanstalk_bucket_name']
      if !bucket || bucket.empty?
        log 'Warning:'
        log 'Unable to directly load Elastic Beanstalk configuration.'
        log 'Reason: settings[\'elasticbeanstalk_bucket_name\'] is not set.'
        return false
      end
      true
    end

    def repo
      @repo ||= Repository.new
    end

    def synchronize_repo!
      log 'Preparing the tagged release version for deployment.'
      repo.prepare!(@tag)
    end

    def cli
      @cli ||= HighLine.new
    end

    def configuration
      return @configuration if @configuration
      prefix = fetch_eb ? 'elasticbeanstalk' : 'config'
      @configuration =
        S3::Configuration.new(settings["#{prefix}_bucket_name"])
    end

    def configure!
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
      apps.map { |app| app.key.sub('/', '') }
    end

    def deployment_target
      choice = select_app_name(apps_list)
      return choice unless fetch_eb
      select_app_name(eb_env_list(choice))
    end

    def eb_env_list(app)
      beanstalk_application(app).environments
    end

    def select_app_name(list)
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
      apps.detect { |app| app.key == @name + '/' }
    end

    def apps
      configuration.apps.reject{|app| EB_INTERNALS.include? app.key }
    end

    def eb
      @eb ||= Eb::State.new(@name)
    end

    def s3
      @s3 ||= S3::State.new(@name, app_bucket)
    end

    def beanstalk_application(app)
      @beanstalk_application ||= Eb::Application.new(app)
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

    def deploy!
      log 'Deployment commencing.'
      success = @platform.deploy!
      abort "Deployment Failed or timed out. See system output." unless success
      log 'All done.'
    end
  end
end
