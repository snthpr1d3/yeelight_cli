RSpec.describe YeelightCli::ColorProcessor do
  describe '.color_temperature_to_rgb' do
    it 'converts a color temperature to rgb correctly' do
      expect(described_class.color_temperature_to_rgb(1700)).to be 16_742_656
      expect(described_class.color_temperature_to_rgb(2000)).to be 16_746_766
      expect(described_class.color_temperature_to_rgb(4000)).to be 16_764_582
      expect(described_class.color_temperature_to_rgb(6000)).to be 16_774_893
    end
  end

  describe 'huesat_to_rgb' do
    it 'converts a huesat to rgb correctly' do
      expect(described_class.huesat_to_rgb(0, 100)).to be 16_711_680
      expect(described_class.huesat_to_rgb(0, 50)).to be 16_744_319
      expect(described_class.huesat_to_rgb(180, 75)).to be 4_194_303
      expect(described_class.huesat_to_rgb(340, 30)).to be 16_757_452
      expect(described_class.huesat_to_rgb(340, 0)).to be 16_777_215
    end
  end
end
