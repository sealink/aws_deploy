module S3
  class State
    def initialize(app_configs)
      @app_configs = app_configs
      @name = app_configs.key.sub('/','')
    end

    def exists?
      target_bucket.exists?
    end

    def version
      @version ||= version_select
    end

    def target
      target_bucket.name
    end

    private

    def target_bucket
      call_with_error_handling do
        Aws::S3::Bucket.new(name: @name)
      end
    end

    def version_select
      # Provide the configuration versions and let user choose
      versions = version_folders.map{|obj| obj.key.split('/').last }

      puts "Found configuration versions:"
      cli = HighLine.new
      cli.choose do |menu|
        menu.prompt =  "Select index of the configuration to use:"
        menu.choices *versions
      end
    end

    def version_folders
      @version_folders ||= read_version_folders
    end

    # The assumed structure of a config folder in S3 is:
    # sealink-config/<app>/config/<version>
    def read_version_folders
      call_with_error_handling do
        @app_configs.bucket.objects.select do |o|
          !o.key.empty? &&
          o.key.start_with?("#{@name}/config/") &&
          o.key.end_with?('/') &&
          o.key.count('/') == 3
        end
      end
    end

    def call_with_error_handling
      yield
    rescue Aws::S3::Errors::ServiceError => e
      # rescues all errors returned by Amazon Simple Storage Service
      fail "Error thrown by AWS S3: #{e}"
    end
  end
end
