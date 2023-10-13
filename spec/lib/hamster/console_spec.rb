RSpec.describe Hamster do
  describe '#console' do
    it 'should run irb start' do
      allow(IRB).to receive(:start)
      Hamster.wakeup({console: 585})

      expect(IRB).to have_received(:start)
    end
  end
end
