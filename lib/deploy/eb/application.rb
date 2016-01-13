module Eb
  class Application
    def initialize(name)
      @name = name
    end

    def environments
      request = {application_name: @name}
      response = elasticbeanstalk.describe_environments(request)
      response.environments.map(&:environment_name)
    end

    private

    def elasticbeanstalk
      @elasticbeanstalk ||=
        call_with_error_handling { Aws::ElasticBeanstalk::Client.new }
    end

    def call_with_error_handling
      yield
    rescue Aws::ElasticBeanstalk::Errors::ServiceError => e
      # rescues all errors returned by Amazon Elastic Beanstalk
      fail "Error thrown by AWS EB: #{e}"
    end
  end
end
