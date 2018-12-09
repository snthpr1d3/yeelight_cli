RSpec.describe YeelightCli::Bulb do
  let(:color_processor) { double(:color_processor) }

  let(:subject) do
    YeelightCli::Bulb.new(
      {
        id: '1',
        name: 'room/group/subgroup/name',
        Location: 'https://127.0.0.1/1',
        support: %w[get_prop cron_get]
      },
      color_processor: color_processor
    )
  end

  describe '#to_s' do
    before do
      allow(subject).to receive(:delayed_shutdown)
      allow(subject).to receive(:on?).and_return(true)
    end

    it 'returns expected string' do
      expect(subject.to_s)
        .to eq(
          '<YeelightCli::Bulb id=1 name=room/group/subgroup/name'\
          " icon=\e[m○\e[0m>"
        )
    end
  end

  describe '#get_prop' do
    context 'state caching is off' do
      before do
        allow(subject).to receive(:state_caching?).and_return(false)
      end

      it 'calls load props' do
        expect(subject).to receive(:load_props)
          .with(:prop)
          .and_return(prop: :value)

        expect(subject.get_prop(:prop)).to be :value
      end
    end

    context 'state caching is on' do
      before do
        allow(subject).to receive(:state_caching?).and_return(true)
      end

      context 'there is no such cached value' do
        it 'calls load props' do
          expect(subject).to receive(:load_props)
            .with(:prop)
            .and_return(prop: :value)

          expect(subject.get_prop(:prop)).to be :value
        end
      end

      context 'there is such a cached value' do
        before do
          subject.state[:prop] = :cached_value
        end

        it 'gets cached value' do
          expect(subject.get_prop(:prop)).to be :cached_value
        end
      end
    end
  end

  describe '#group_name' do
    it 'returns group names corretly' do
      expect(subject.group_name).to eq('room')
      expect(subject.group_name(2)).to eq('group')
      expect(subject.group_name(3)).to eq('subgroup')
      expect(subject.group_name(4)).to be nil
    end
  end

  describe '#to_icon' do
    before do
      allow(subject).to receive(:off?).and_return(true)
    end

    it 'returns icon' do
      expect(subject.to_icon).to eq("\e[38;5;244mx\e[0m")
    end
  end

  describe '#brightness_character' do
    before do
      allow(subject).to receive(:off?).and_return(true)
    end

    it 'returns character' do
      expect(subject.brightness_character).to eq('x')
    end
  end

  describe '#current_color_in_rgb' do
    before do
      allow(subject).to receive(:off?).and_return(false)
    end

    context 'the bulb is off' do
      before do
        allow(subject).to receive(:off?).and_return(true)
      end

      it 'returns 0x888888' do
        expect(subject.current_color_in_rgb).to be 0x888888
      end
    end

    context 'the color mode is hsv' do
      before do
        allow(subject).to receive(:color_mode_name).and_return(:hsv)

        allow(color_processor).to receive(:huesat_to_rgb)
          .with(0, 0)
          .and_return(:value)
      end

      it 'it converts huesat to rgb' do
        expect(subject.current_color_in_rgb).to be :value
      end
    end

    context 'the color mode is temperature' do
      before do
        allow(subject).to receive(:color_mode_name).and_return(:temperature)

        allow(color_processor).to receive(:color_temperature_to_rgb)
          .with(0)
          .and_return(:value)
      end

      it 'it converts color temperature to rgb' do
        expect(subject.current_color_in_rgb).to be :value
      end
    end

    context 'the color mode is rgb' do
      before do
        allow(subject).to receive(:color_mode_name).and_return(:rgb)
        allow(subject).to receive(:rgb).and_return(:value)
      end

      it 'it returns rgb value' do
        expect(subject.current_color_in_rgb).to be :value
      end
    end
  end

  describe '#support?' do
    it 'returns true for set_name method' do
      expect(subject.support?('set_name')).to be true
    end

    it 'checks specifications for other methods' do
      expect(subject.support?('get_prop')).to be true
      expect(subject.support?('unsupported_method')).to be false
    end
  end
end
