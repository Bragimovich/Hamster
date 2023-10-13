require "#{Dir.pwd}/lib/ashman/ashman"
module Hamster
  RSpec.describe Ashman do
    let(:bucket) { 'hamster-storage1' }
    let(:key) { 'rspec_test_pdf' }
    let(:test_pdf) {"#{RSPEC_ROOT}/support/fixtures/test.pdf"}
    let(:aws_s3_obj_instance) { instance_double(Aws::S3::Object) }
    let(:double_class) { class_double(Aws::S3::Object).as_stubbed_const }
    let(:aws_s3_client_instance) { instance_double(Aws::S3::Client) }
    let(:client_double_class) { class_double(Aws::S3::Client).as_stubbed_const }
    let(:metadata) { 'test metadata' }
    let(:ashman) { described_class.new({:aws_opts => {}, account: :hamster, bucket: bucket}) }

    describe '#new' do
      it 'should return ashman client' do
        expect(ashman).not_to be_nil
      end
    end

    describe '#default_options' do
      it 'should not returns nil' do
        expect(ashman.default_options).not_to be_nil
      end

      it 'should returns default options' do
        expect(ashman.default_options[:region]).to eq('us-east-1')
        expect(ashman.default_options[:http_open_timeout]).to eq(30)
        expect(ashman.default_options[:http_read_timeout]).to eq(120)
        expect(ashman.default_options[:http_idle_timeout]).to eq(15)
      end

      it 'should returns customized option' do
        ashman = described_class.new({:aws_opts => {http_open_timeout: 25, http_idle_timeout: 10}, account: :hamster, bucket: bucket})
        expect(ashman.default_options[:http_open_timeout]).to eq(25)
        expect(ashman.default_options[:http_idle_timeout]).to eq(10)
      end
    end

    describe '#upload' do
      it 'should raise file size error' do
        expect { ashman.upload(key: key, file_path: test_pdf) }.to raise_error('!!! Error: file size is less than 100 MB')
      end

      it 'should raise exist error when file object is already in the aws storage' do
        allow(File).to receive(:size).with(test_pdf).and_return(101.megabytes)
        allow(ashman).to receive(:object_exists?).with(bucket, key).and_return(true)
        expect { ashman.upload(key: key, file_path: test_pdf) }.to raise_error('!!! Error: the object already exists')
      end

      it 'should call upload_file' do
        allow(File).to receive(:size).with(test_pdf).and_return(101.megabytes)
        allow(ashman).to receive(:object_exists?).with(bucket, key).and_return(false)

        allow(double_class).to receive(:new).and_return(aws_s3_obj_instance)
        allow(aws_s3_obj_instance).to receive(:upload_file).once

        ashman.upload(key: key, file_path: test_pdf)

        expect(aws_s3_obj_instance).to have_received(:upload_file).with(test_pdf)
      end
    end

    describe '#download' do
      let(:download_path) { '/home/download_path' }

      it 'should call download_file' do
        allow(double_class).to receive(:new).and_return(aws_s3_obj_instance)
        allow(aws_s3_obj_instance).to receive(:download_file).once


        ashman.download(key: key, download_path: download_path)

        expect(aws_s3_obj_instance).to have_received(:download_file).with(download_path)
      end
    end

    describe '#get_metadata' do
      it 'should return metadata' do
        allow(client_double_class).to receive(:new).and_return(aws_s3_client_instance)
        allow(aws_s3_client_instance).to receive(:head_object)

        expect{ ashman.get_metadata(key) }.to raise_error("!!! Error: can't find the object")
      end

      it 'should return metadata' do
        allow(client_double_class).to receive(:new).and_return(aws_s3_client_instance)
        allow(aws_s3_client_instance).to receive(:head_object).and_return(OpenStruct.new(metadata: metadata))

        metadata = ashman.get_metadata(key)

        expect(aws_s3_client_instance).to have_received(:head_object).with(bucket: bucket, key: key)
        expect(metadata).to eq(metadata)
      end
    end

    describe '#change_metadata' do
      it 'should called copy_object' do
        allow(client_double_class).to receive(:new).and_return(aws_s3_client_instance)
        allow(aws_s3_client_instance).to receive(:copy_object)

        ashman.change_metadata(key: key, metadata: metadata)

        expect(aws_s3_client_instance).to have_received(:copy_object).with(
          bucket: bucket,
          copy_source: "#{bucket}/#{key}",
          key: key,
          metadata: metadata,
          metadata_directive: 'REPLACE'
        )
      end
    end

    describe '#delete' do
      it 'should called delete_object' do
        allow(client_double_class).to receive(:new).and_return(aws_s3_client_instance)
        allow(aws_s3_client_instance).to receive(:delete_object)

        ashman.delete(key)
        expect(aws_s3_client_instance).to have_received(:delete_object).with(bucket: bucket, key: key)
      end
    end

    describe '#list' do
      let(:prefix) { 'tasks/scrape_tasks/st00499/' }
      it 'should called list_objects' do
        allow(client_double_class).to receive(:new).and_return(aws_s3_client_instance)
        allow(aws_s3_client_instance).to receive(:list_objects)

        opts = { prefix: prefix }
        ashman.list(opts)

        expect(aws_s3_client_instance).to have_received(:list_objects).with(bucket: bucket, prefix: prefix)
      end
    end

    describe '#object_exists?' do
      it 'should called head_object' do
        allow(client_double_class).to receive(:new).and_return(aws_s3_client_instance)
        allow(aws_s3_client_instance).to receive(:head_object)

        ashman.object_exists?(bucket, key)
        expect(aws_s3_client_instance).to have_received(:head_object).with(bucket: bucket, key: key)
      end
    end
  end
end
