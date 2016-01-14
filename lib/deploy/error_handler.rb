require 'singleton'

module Deploy
  class ErrorHandler
    include Singleton

    ERROR_MESSAGES = {
      'Aws::Errors::MissingCredentialsError'        => 'Missing AWS credentials. Error thrown by AWS',
      'Aws::ElasticBeanstalk::Errors::ServiceError' => 'Error thrown by AWS EB',
      'Aws::S3::Errors::ServiceError'               => 'Error thrown by AWS S3'
    }

    def self.with_error_handling(&block)
      instance.with_error_handling(&block)
    end

    def with_error_handling
      yield
    rescue RuntimeError => error
      fail message_for(error)
    end

    private

    def message_for(error)
      message = ERROR_MESSAGES[error.class.name] || 'Unknown error'
      "#{message}: #{error}"
    end
  end
end
