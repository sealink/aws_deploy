module Deploy
  module Eb
    class State
      def initialize(env)
        @env = env
      end

      def exists?
        !environment_info.nil?
      end

      def ready?
        environment_info.status.eql? 'Ready'
      end

      def switch
        system("eb use #{@env}")
      end

      def environment_info
        @environment_info ||= environment_description_message.environments[0]
      end

      def application_name
        environment_info.application_name
      end

      def version_exists?(version)
        request = {application_name: application_name, version_labels: [version]}
        response = elasticbeanstalk.describe_application_versions(request)
        ! response.application_versions.empty?
      end

      private

      def elasticbeanstalk
        @elasticbeanstalk ||=
          ErrorHandler.with_error_handling { Aws::ElasticBeanstalk::Client.new }
      end

      def environment_description_message
        ErrorHandler.with_error_handling do
          elasticbeanstalk.describe_environments(
            environment_names: [@env]
          )
        end
      end
    end
  end
end
