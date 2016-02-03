module Deploy
  module S3
    class Configuration

      def initialize(config_bucket_name)
        @config_bucket_name = config_bucket_name
      end

      def verify!
        unless config_bucket.exists? && objects.count > 0
          fail "Configuration bucket #{@config_bucket_name} not found or empty."
        end
        enforce_valid_app_paths!
        @verified = true
      end

      def apps
        fail "Asked for app list without verifying. It will be wrong." if !@verified
        @apps ||= app_names
      end

      def created_folders
        @created_folders ||= []
      end

      def config_bucket_for(name)
        app_buckets.detect { |app| app.key == name + '/' }
      end

      private

      def config_bucket
        @config_bucket ||=
          ErrorHandler.with_error_handling { Aws::S3::Bucket.new(@config_bucket_name) }
      end

      def objects
        @objects ||= ErrorHandler.with_error_handling { config_bucket.objects }
      end

      def client
        @client ||= ErrorHandler.with_error_handling { Aws::S3::Client.new }
      end

      def enforce_valid_app_paths!
        # check folders in our config bucket, recreate any missing folders
        object_names = objects.map(&:key)
        file_names = object_names.select { |name| !name.end_with?('/') }
        max_depth = object_names.map { |name| name.count('/') }.max
        possible_object_names = (1..max_depth).reduce([]) { |list, depth|
          list += object_names.map { |name| name.split('/').first(depth).join('/') }
        }
        folder_names = possible_object_names.uniq - file_names
        path_names = folder_names.map { |folder| folder + '/' }

        # Make the folder if needed
        folders_to_create = path_names.
          sort_by { |name| name.count('/') }.
          select{|folder| ! folder_exists?(folder) }
        folders_to_create.each do |folder|
          create_folder!(folder)
        end

        @created_folders = folders_to_create
      end

      def create_folder!(folder)
        ErrorHandler.with_error_handling do
          client.put_object(
            acl: 'private',
            body: nil,
            bucket: config_bucket.name,
            key: folder
          )
        end
      end

      def folder_exists?(folder)
        ErrorHandler.with_error_handling do
          config_bucket.object(folder).exists?
        end
      end

      def app_buckets
        @app_buckets ||= app_buckets_list
      end

      def app_buckets_list
        ErrorHandler.with_error_handling do
          objects.select do |o|
            !o.key.empty?        &&
              o.key.end_with?('/') &&
              o.key.count('/') == 1
          end
        end
      end

      def app_names
        app_buckets.map{|o| o.key.sub('/', '') }
      end
    end
  end
end
