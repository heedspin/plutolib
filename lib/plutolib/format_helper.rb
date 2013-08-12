module Plutolib::FormatHelper
  # Shorten, truncate, add ellipse...
  def limit_string(text, max)
    return nil unless text.present? && (text.size > 0)
    text[0..(max-1)].strip + (text.size > max ? '...' : '')
  end
end