# frozen_string_literal: true

class StreamLanguageService
  # These languages seems to be wide spread
  MAJOR_LOCALES = %w[en de fr es ru].freeze
  FALLBACK_LOCALE = "en"

  def initialize(user=nil)
    @user = user
  end

  def language_for_stream
    return default_language if @user.nil? || @user.stream_languages.empty?

    user_defined_language
  end

  private

  def user_defined_language
    @user.stream_languages.pluck(:language_id)
  end

  # If current locale send by request is in the MAJOR_LOCALES list, this will be returned
  # Otherwise an array of the more special language sent by the browser together with a FALLBACK_LOCALE
  # is send.
  # @example Request sends a 'en' or 'de' language, this will be returned. If a little used language is send like 'dk'
  # (Danish) this language identifier will be returned together with the FALLBACK_LOCALE
  # @return [[Language String (frozen)], Array]
  def default_language
    default_language = I18n.locale.to_s
    return [default_language] if MAJOR_LOCALES.include?(default_language)

    [default_language, FALLBACK_LOCALE] # all other requested languages should return english plus the requested language
  end
end
