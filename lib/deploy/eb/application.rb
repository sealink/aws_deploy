module Deploy
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
          ErrorHandler.with_error_handling { Aws::ElasticBeanstalk::Client.new }
      end
    end
  end
end
