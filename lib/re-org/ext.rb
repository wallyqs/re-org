module StringWithColors
  def red;    colorize("\e[0m\e[31m");  end
  def green;  colorize("\e[0m\e[32m");  end
  def yellow; colorize("\e[0m\e[33m");  end
  def bold;   colorize("\e[0m\e[1m");   end
  def colorize(color_code); "#{color_code}#{self}\e[0m"; end
end
class String
  include StringWithColors
end
