module Deploy
  module IAM
    class Client

      REGION_ERROR='Please configure your AWS region in ENV[\'AWS_REGION\'].'
      CREDENTIALS_ERROR='Please set your AWS credentials.
                         Credentials are read from ~/.aws/credentials, '\
                         'if possible.
                         Otherwise, credentials are loaded from '\
                         'ENV[\'AWS_ACCESS_KEY_ID\'] and '\
                         'ENV[\'AWS_SECRET_ACCESS_KEY\'].'

      def self.connection
        Aws::IAM::CurrentUser.new.arn
      rescue Aws::Errors::MissingRegionError
        fail ArgumentError, REGION_ERROR
      rescue Aws::Errors::MissingCredentialsError
        fail ArgumentError, CREDENTIALS_ERROR
      end

    end
  end
end
