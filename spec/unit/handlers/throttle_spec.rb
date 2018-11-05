require 'iolaus/handlers/throttle'

RSpec.describe(Iolaus::Handlers::Throttle) do
  subject { described_class.instance }

  context 'when multiple wait timers are set on the same hostname within a short period' do
    it 'creates a single timer' do
      timer1 = subject.set_timer('foo.test', 1.0)
      timer2 = subject.set_timer('foo.test', 1.0)

      expect(timer1).to eq(timer2)
    end
  end
end
