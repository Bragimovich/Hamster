RSpec.describe Hamster do
  describe '#dig' do
    let(:project_number) { 0000 }
    let(:root_dir) { 'projects/project_%04d/' % project_number }
    let(:current_month) { "\n_#{Date.today.strftime("%B %Y")}_\n" }

    it 'should create project folders for new task 0000' do
      allow(Hamster).to receive(:check_project_number).and_return(true)
      allow(FileUtils).to receive(:mkdir_p).and_return(true)
      allow(FileUtils).to receive(:touch).and_return(true)
      allow(File).to receive(:read).and_return('')
      allow(File).to receive(:write).and_return(true)

      Hamster.wakeup({dig: project_number})

      project_dirs  = %w[bin/ lib/ models/ sql/]
      expect(Hamster).to have_received(:check_project_number).with(:dig)
      expect(File).to have_received(:read).exactly(4).times
      expect(File).to have_received(:write).exactly(4).times
      expect(FileUtils).to have_received(:touch).twice
      project_dirs.each do |dir|
        expect(FileUtils).to have_received(:mkdir_p).with(root_dir + dir)
      end
    end
  end
end
