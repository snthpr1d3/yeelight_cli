# frozen_string_literal: true

module YeelightCli
  # The class contains color processing methods
  class ColorProcessor
    BaseError = Class.new(StandardError)
    InvalidArgumentError = Class.new(BaseError)

    class << self
      def color_temperature_to_rgb(color_temperature)
        raise InvalidArgumentError if color_temperature < 600

        green = calculate_rgb_green_by_color_temperature(color_temperature)
        blue = calculate_rgb_blue_by_color_temperature(color_temperature)

        hex_green = green.round.clamp(0, 0xff).to_s(16).rjust(2, '0')
        hex_blue = blue.round.clamp(0, 0xff).to_s(16).rjust(2, '0')

        "ff#{hex_green}#{hex_blue}".to_i(16)
      end

      def huesat_to_rgb(hue, sat)
        check_huesat!(hue, sat)

        hi = (hue / 60).round % 6
        vmin, vinc, vdec = calculate_huesat_coeffs(hue, sat)

        huesat_coeffs_to_rgb_array(vmin, vinc, vdec, hi)
          .map { |color| (color * 255 / 100).round.to_s(16).rjust(2, '0') }
          .join
          .to_i(16)
      end

      private

      def check_huesat!(hue, sat)
        raise InvalidArgumentError unless (0..359).cover?(hue)
        raise InvalidArgumentError unless (0..100).cover?(sat)
      end

      def calculate_rgb_green_by_color_temperature(color_temperature)
        99.4708025861 * Math.log(color_temperature / 100) - 161.1195681661
      end

      def calculate_rgb_blue_by_color_temperature(color_temperature)
        coeff = color_temperature / 100
        coeff > 19 ? 138.5177312231 * Math.log(coeff - 10) - 305.0447927307 : 0
      end

      def calculate_huesat_coeffs(hue, sat)
        vmin = 100 - sat
        a = (100 - vmin) * (hue % 60) / 60
        vinc = vmin + a
        vdec = 100 - a
        [vmin, vinc, vdec]
      end

      # rubocop:disable CyclomaticComplexity
      # rubocop:disable MethodLength
      # rubocop:disable UncommunicativeMethodParamName
      def huesat_coeffs_to_rgb_array(vmin, vinc, vdec, hi)
        case hi
        when 0
          [100, vinc, vmin]
        when 1
          [vdec, 100, vmin]
        when 2
          [vmin, 100, vinc]
        when 3
          [vmin, vdec, 100]
        when 4
          [vinc, vmin, 100]
        when 5
          [100, vmin, vdec]
        end
      end
      # rubocop:enable CyclomaticComplexity
      # rubocop:enable MethodLength
      # rubocop:enable UncommunicativeMethodParamName
    end
  end
end
