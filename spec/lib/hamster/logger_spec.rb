require 'logger'
RSpec.describe Hamster do
  describe '#logger' do
    let(:project_number) { 0000 }
    let(:log_dir) { ENV['HOME'] + '/HarvestStorehouse/project_%04d/log' % project_number }
    let(:log_file) {'project_%04d.log' % project_number}
    let(:log_path) { "#{log_dir}/#{log_file}" }
    
    it 'should return the logger instance' do
      allow(Hamster::Logger).to receive(:instance).and_return(true)
      Hamster.wakeup({console: project_number})
      expect(Hamster.logger).not_to be_nil
      expect(Hamster::Logger).to have_received(:instance)
    end

    it 'should return the same logger instance per project' do
    end

    it 'should return logger instance that level is `info` in production mode' do
      allow(Hamster).to receive(:check_project_number).and_return(true)
      allow(FileUtils).to receive(:mkdir_p).and_return(true)
      allow(Hamster).to receive(:project_number).and_return('0000')
      expect_any_instance_of(Logger).to receive(:initialize).with(log_path, 10, 5 * 1024 * 1024, datetime_format: '%m/%d/%Y %H:%M:%S', level: :info)

      Hamster.wakeup({console: project_number})
      expect(Hamster.logger).not_to be_nil

      expect(Hamster).to have_received(:check_project_number).with(:console)
      expect(FileUtils).to have_received(:mkdir_p).with(log_dir)
    end
  end
end
