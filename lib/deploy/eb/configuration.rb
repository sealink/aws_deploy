module Deploy
  module Eb
    class Configuration
      def apps
        @apps ||= app_names
      end

      private

      def client
        @client ||=
          ErrorHandler.with_error_handling { Aws::ElasticBeanstalk::Client.new }
      end

      def apps_list
        ErrorHandler.with_error_handling do
          client.describe_applications[0]
        end
      end

      def app_names
        apps_list.map(&:application_name)
      end
    end
  end
end
