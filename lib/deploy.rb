require 'aws-sdk'
require 'highline'
require 'deploy/eb/application'
require 'deploy/eb/configuration'
require 'deploy/eb/platform'
require 'deploy/eb/state'
require 'deploy/iam/client'
require 'deploy/s3/configuration'
require 'deploy/s3/state'
require 'deploy/s3/platform'
require 'deploy/error_handler'
require 'deploy/repository'
require 'deploy/version'

module Deploy
  class Runner
    def initialize(tag)
      @tag = tag
    end

    def run
      trap_int
      precheck!
      validate!
      perform!
    end

    private

    def precheck!
      check_for_unstaged_changes!
      check_for_changelog!
      check_for_aws_access!
    end

    def validate!
      configure!
      @name       = deployment_target
      @platform   = detect_platform
    end

    def perform!
      request_confirmation!
      synchronize_repo!
      deploy!
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

    def on_beanstalk?
      @on_beanstalk ||= Eb::Platform.configured?
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
      @configuration ||= set_configuration
    end

    def set_configuration
      if on_beanstalk?
        Eb::Configuration.new
      else
        S3::Configuration.new(config_bucket_name)
      end
    end

    def config_bucket_name
      @config_bucket_name ||= set_config_bucket_name!
    end

    def set_config_bucket_name!
      bucket_name = ENV['S3_CONFIG_BUCKET']
      unless bucket_name
        fail 'Please set your S3 config bucket name in '\
             'ENV[\'S3_CONFIG_BUCKET\']'
      end
      bucket_name
    end

    def configure!
      return if on_beanstalk?
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

    def deployment_target
      app = select_from_list(apps)
      return app unless on_beanstalk?
      select_from_list(eb_env_list(app))
    end

    def eb_env_list(app)
      beanstalk_application(app).environments
    end

    def select_from_list(list)
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
      configuration.config_bucket_for(@name)
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
