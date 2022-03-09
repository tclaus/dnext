# frozen_string_literal: true

class StreamLanguageService
  # These languages seems to be wide spread
  MAJOR_LOCALES = %w[en de fr es ru].freeze
  FALLBACK_LOCALE = "en"

  def initialize(user=nil)
    @user = user
  end

  def language_for_stream
    return default_language if @user.nil?

    user_defined_language
  end

  private

  def user_defined_language
    @user.stream_languages.pluck(:language_id)
  end

  def default_language
    default_language = I18n.locale.to_s
    return [default_language] if MAJOR_LOCALES.include?(default_language)

    [default_language, FALLBACK_LOCALE] # all other requested languages should return english plus the requested language
  end
end
