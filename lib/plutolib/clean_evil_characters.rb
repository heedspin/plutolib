module Plutolib::CleanEvilCharacters
  # DEC to OCT to HEX Mapping:
  # 128.chr => \200 => \x80
  # 153.chr => \231 => \x99
  # 156.chr => \234 => \x9c
  # 157.chr => \235 => \x9d
  # 162.chr => \242 => \xA2
  # 188.chr => \274 => \xBC
  # 194.chr => \302 => \xC2
  # 195.chr => \303 => \xC3  ==> bang
  # 226.chr => \342 => \xE2
  EVIL_CHARACTERS = [153, 160, 162, 188, 194, 195, 226]
  def clean_evil_characters(txt)
    return txt unless txt.is_a?(String)

    # Evil curly quote replace
    txt = txt.gsub("\xE2\x80\x9c", '"')
    txt = txt.gsub("\xE2\x80\x9d", '"')

    # Get rid of evil A characters:
    # <"Miguel&#39;s"> expected but was
    # <"MiguelÂ&#39;s">.
    EVIL_CHARACTERS.each { |evilc| txt = txt.delete evilc.chr }

    # Replace evil quotes with regular quotes.
    txt = txt.tr "\x91-\x94\x9c\x9d\x80", "''\"\"\"\"'"

    # Entity encode quotes.
    # txt = txt.gsub("'", '&#39;')
    # txt = txt.gsub('"', '&#34;')
    txt.strip
  end
end