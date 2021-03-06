module Deploy
  module S3
    class Platform
      def initialize(opts)
        @s3 = opts[:s3]
        @tag = opts[:tag]
      end

      def deploy!
        # TODO: Add option to re-use existing deployment if we can
        s3_deploy!
      end

      private

      def s3_deploy!
        system(
          "bucket=#{@s3.target}"\
        " s3_config_version=#{@s3.version}"\
        " npm run publish"
        )
      end
    end
  end
end
