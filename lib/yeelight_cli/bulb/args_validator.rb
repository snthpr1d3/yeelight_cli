# frozen_string_literal: true

# The class contains all the params validations
# rubocop:disable ClassLength
class YeelightCli::Bulb::ArgsValidator
  BaseError = Class.new(StandardError)
  IncorrectArgumentError = Class.new(BaseError)
  WrongInitialDataFormatError = Class.new(BaseError)

  class << self
    def check_initial_data!(initial_data)
      raise WrongInitialDataFormatError unless initial_data.is_a?(Hash)

      raise WrongInitialDataFormatError if initial_data[:id].blank?

      raise WrongInitialDataFormatError if initial_data[:Location].blank?

      raise WrongInitialDataFormatError if initial_data[:support].blank?
    end

    def check_duration!(duration)
      return if duration.is_a?(Integer) && !duration.negative?

      raise IncorrectArgumentError, 'Duration must be integer >= 0'
    end

    def check_brightness!(brightness)
      return if (1..100).cover?(brightness)

      raise IncorrectArgumentError, 'Brightness must be in 1..100'
    end

    def check_power_state!(power_state)
      return if %i[on off].include?(power_state)

      raise IncorrectArgumentError, 'Power state must be :on or :off'
    end

    def check_color_temperature!(color_temperature)
      return if (1700..6500).cover?(color_temperature)

      raise IncorrectArgumentError, 'Color temperature must be in 1700..6500'
    end

    def check_hue!(hue)
      return if (0..359).cover?(hue)

      raise IncorrectArgumentError, 'Hue must be in 0..359'
    end

    def check_sat!(sat)
      return if (0..100).cover?(sat)

      raise IncorrectArgumentError, 'Sat must be in 0..100'
    end

    def check_rgb!(rgb)
      return if (0x000001..0xffffff).cover?(rgb)

      raise IncorrectArgumentError, 'Rgb must be in 0x000001..0xffffff'
    end

    def check_timeout!(minutes)
      return if (0..1440).cover?(minutes)

      raise IncorrectArgumentError, 'Minutes must be in 0..1440'
    end

    def check_adjust_action!(action)
      return if action.to_sym.in?(%i[increase decrease circle])

      raise IncorrectArgumentError,
            'Action must be :increase, :decrease or :circle'
    end

    def check_adjust_prop!(prop)
      return if prop.to_sym.in?(%i[bright ct color])

      raise IncorrectArgumentError, 'Adjust prop must be :bright, :ct or :color'
    end

    def check_percentage!(percentage)
      return if (-100..100).cover?(percentage) && !percentage.zero?

      raise IncorrectArgumentError, 'Percentage must be in -100..-1 1..100'
    end

    def check_cf_action!(action)
      return if (0..2).cover?(action)

      raise IncorrectArgumentError, 'Cf action must be in 0..2'
    end

    # rubocop:disable MethodLength
    def check_cf_expression!(expression)
      if expression.blank?
        raise IncorrectArgumentError, 'Expression must not be blank'
      end

      exp_array = expression.is_a?(Array) ? expression : expression.split(',')

      if exp_array.count % 4 != 0
        raise IncorrectArgumentError,
              'Expression array must contain n*4 elements'
      end

      exp_array.each_slice(4) do |duration, mode, value, brightness|
        check_cf_slice!(duration, mode, value, brightness)
      end
    end
    # rubocop:enable MethodLength

    def check_cf_slice!(duration, mode, value, brightness)
      check_cf_duration!(duration.to_i)
      check_cf_mode!(mode.to_i)
      check_rgb!(value.to_i) if mode == 1
      check_color_temperature!(value.to_i) if mode == 2
      check_cf_brightness!(brightness.to_i) if mode != 7
    end

    def check_cf_duration!(duration)
      return if duration.is_a?(Integer) && duration >= 50

      raise IncorrectArgumentError, 'Duration must be an integer >= 50'
    end

    def check_cf_mode!(mode)
      return if mode.in?([1, 2, 7])

      raise IncorrectArgumentError, 'Mode must be 1, 2 or 7'
    end

    def check_cf_brightness!(brightness)
      return if (-1..100).cover?(brightness)

      raise IncorrectArgumentError, 'Brightness must be in -1..100'
    end

    def check_cf_count!(count)
      raise IncorrectArgumentError, 'Count must be >= 0' unless count >= 0
    end

    def check_music_action!(action)
      return if action.in?(%i[on off])

      raise IncorrectArgumentError, 'Action must be :on or :off'
    end

    # rubocop:disable RescueModifier
    def check_host!(host)
      return if (IPAddr.new(host) rescue nil).present?

      raise IncorrectArgumentError, 'Wrong host'
    end
    # rubocop:enable RescueModifier

    def check_port!(port)
      return if (1..65_535).cover?(port)

      raise IncorrectArgumentError, 'Port must be in 1..65535'
    end
  end
end
# rubocop:enable ClassLength
