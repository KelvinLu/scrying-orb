class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

class String
  def color_256(rgb)
    b = rgb & 0xff
    g = (rgb >> 8) & 0xff
    r = (rgb >> 16) & 0xff

    "\e[38;2;#{r};#{g};#{b}m#{self}\e[0m"
  end

  def bg_color_256(rgb)
    b = rgb & 0xff
    g = rgb >> 8 & 0xff
    r = rgb >> 16 & 0xff

    "\e[48;2;#{r};#{g};#{b}m#{self}\e[0m"
  end
end

module Color
  class Gradient
    def initialize(*colors)
      @colors = colors
    end

    def call(ratio)
      raise ArgumentError if ratio < 0.0 || ratio > 1.0

      @colors[[(@colors.length * ratio).to_i, @colors.length - 1].min]
    end

    TURQUOISE = self.new(
      0x011210,
      0x061614,
      0x0b1a18,
      0x0e1d1b,
      0x10201f,
      0x132423,
      0x152826,
      0x172c2a,
      0x1a302e,
      0x1c3332,
      0x1f3736,
      0x213b3a,
      0x233f3e,
      0x264342,
      0x284747,
      0x2b4c4b,
      0x2e504f,
      0x305454,
      0x335858,
      0x355c5d,
      0x386161,
      0x3a6566,
      0x3d696a,
      0x406e6f,
      0x427274,
      0x457779,
      0x487b7e,
      0x4b8083,
      0x4d8488,
      0x50898d,
      0x538e92,
      0x569297,
      0x59979c,
      0x5b9ba1,
      0x5ea0a6,
      0x61a5ab,
      0x64aab1,
      0x67aeb6,
      0x6ab3bc,
      0x6db8c1,
    )
  end
end
