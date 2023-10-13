# frozen_string_literal: true

# @author Oleksii Kuts <oleksiikuts@gmail.com>
module Hamster
  module Ashman
    # Ashman::Client is a client that communicates with the AWS::S3::Client.
    class Client
      # The minimum file size for uploads, in megabytes.
      # This constant is defined using the `megabytes` method from ActiveSupport.
      #
      # @!attribute MIN_FILE_SIZE
      #   @return [Integer] the minimum file size, in bytes
      # @see https://apidock.com/rails/Numeric/megabytes
      MIN_FILE_SIZE = 100.megabytes

      # The client used for accessing the service.
      # @return [Client] the client object
      # @!attribute [r] client
      attr_reader :client

      # The options used for configuring the service.
      # @return [Hash] the options hash
      # @!attribute [r] options
      attr_reader :options

      # The bucket used for storing data.
      # @return [String] the bucket name
      # @!attribute [r] bucket
      attr_reader :bucket

      # Initializes an S3 storage client with the specified options.
      #
      # @param options [Hash] The options to use for initializing the client.
      # @option options [Hash] :aws_opts A hash of options to pass to the underlying `Aws::S3::Client` constructor.
      # @option options [String] :bucket The name of the S3 bucket to use for storage.
      # @option options [Symbol] :account The name of the S3 account to use for.
      #
      # @return [Ashman::Client]
      #
      # @example
      #   ashman = Hamster::Ashman.new({:aws_opts => {}, account: :hamster, bucket: 'hamster-storage1'})
      #
      def initialize(**options)
        @options = options
        @client = Aws::S3::Client.new(options[:aws_opts].merge(default_options))
        @bucket = options[:bucket]
      end

      # @return [Hash]
      def default_options
        accounts = {
          us_court: :aws_credentials,
          loki:     :aws_credentials_loki,
          hamster:  :aws_credentials_hamster_storage
        }
        options[:account] ||= :hamster
        creds = Storage.new.send(accounts[options[:account]])
        options[:bucket]  ||= creds[:bucket]

        aws_opts = options[:aws_opts]

        { region:            creds[:region],
          credentials:       Aws::Credentials.new(creds[:access_key_id], creds[:secret_access_key]),
          http_open_timeout: aws_opts[:http_open_timeout] || 30,
          http_read_timeout: aws_opts[:http_read_timeout] || 120,
          http_idle_timeout: aws_opts[:http_idle_timeout] || 15
        }
      end

      # Uploads a file to S3.
      #
      # @param args [Hash] The options for the upload.
      # @option args [String] :file_path The path to the file to be stored in S3.
      # @option args [String] :key The key in S3 for the stored file.
      # @raise [Ashman::Errors::ServiceError] If the object already exists in the bucket.
      # @raise [Ashman::Errors::ServiceError] If the file size is less than the minimum allowed size.
      # @return [void]
      #
      # @example Upload a file '/path/to/folder/my_file' to S3 with key 'my_file_key'
      #   upload(key: 'my_file_key', file_path: '/path/to/folder/my_file')
      def upload(**args)
        # check file size
        file_size = File.size(args[:file_path])
        if file_size < MIN_FILE_SIZE
          raise Ashman::Error.new("!!! Error: file size is less than #{MIN_FILE_SIZE/1.megabyte} MB", args)
        end

        # check if file already exists
        if object_exists?(bucket, args[:key])
          raise Ashman::Error.new("!!! Error: the object already exists", args)
        end

        obj = Aws::S3::Object.new(bucket, args[:key], {client: @client})
        obj.upload_file(args[:file_path])
      end

      # Downloads a file from an S3.
      #
      # @param args [Hash] The options for the download.
      # @option args [String] :key The key of the file to download
      # @option args [String] :download_path Path to which the file will be downloaded
      # @raise [Aws::S3::Errors::ServiceError] if there's a problem with the S3 service
      # @return [void]
      #
      # @example Download a file with key 'my_file_key' to '/path/to/download/my_file'
      #   download(key: 'my_file_key', download_path: '/path/to/download/my_file')
      def download(**args)
        obj = Aws::S3::Object.new(bucket, args[:key], {client: @client})
        obj.download_file(args[:download_path])
      end

      # Gets file metadata
      #
      # @param key [String] The key of the file
      # @return [Hash] metadata (Hash<String,String>)
      def get_metadata(key)
        resp = @client.head_object(bucket: bucket, key: key)
        resp.metadata
      rescue
        raise Ashman::Error.new("!!! Error: can't find the object", {bucket: bucket, key: key})
      end

      # Changes file metadata
      # @param [Hash] args
      # @option [String] key Key of object in S3
      # @option [Hash] metadata (Hash<String,String>) new metadata for object in S3
      def change_metadata(**args)
        @client.copy_object(
          bucket: bucket,
          copy_source: "#{bucket}/#{args[:key]}",
          key: args[:key],
          metadata: args[:metadata],
          metadata_directive: 'REPLACE'
        )
      end

      # Remove file from S3 bucket
      # @param [String] key - name of file you need to delete
      # @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html#delete_object-instance_method
      def delete(key)
        @client.delete_object(bucket: bucket, key: key)
      end

      # Wraps Aws::S3::Client.list_objects
      # @return [Aws::S3::Types::ListObjectsOutput] some or all (up to 1,000)
      #   of the objects in a bucket. You can use the request parameters as
      #   selection criteria to return a subset of the objects in a bucket.
      #   A 200 OK response can contain valid or invalid XML. Be sure to design
      #   your application to parse the contents of the response and handle it
      #   appropriately.
      # @see #https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Types/ListObjectsOutput.html
      def list(opts = {})
        @client.list_objects(opts.merge(bucket: bucket))
      end

      # @todo Deal with exception when object was not found
      #   we don't know the true reason why it happens
      #   it can be '400 Bad Request', '403 Forbidden' or '404 Not Found'
      #   read about waiters for this action
      # @see https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.html#head_object-instance_method
      def object_exists?(bucket, key)
        @client.head_object(bucket: bucket, key: key)
        true
      rescue
        false
      end
    end

  end
end
