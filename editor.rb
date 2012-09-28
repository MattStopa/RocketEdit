require 'curses'

class Buffer
  attr_accessor :buffer

  def [](num)
  end
end

class Editor
  attr_accessor :offset, :buffer, :previous_x, :previous_y

  NEW_LINE = 10
  LEFT = Curses::Key::LEFT
  RIGHT = Curses::Key::RIGHT
  UP = Curses::Key::UP
  DOWN = Curses::Key::DOWN
  BACKSPACE = 127
  DC = Curses::Key::DC

  def initialize
    @offset = 0
  end

  def writeln(win, y, line, buffer)
    return if line == nil
    special_words = %w(field if else do end def scope)
    l = buffer.size.to_s.size
    y = y.to_s
    (l - y.size ).times { y += ' ' }
    win.addstr("#{y}|")
    arr = line.split(' ')
    spaces = line.split(/[abcdefghijklmnoprstuvwxyz1234567890-_=+]/)
    arr.each_with_index do |element, index|
      win.addstr(spaces[index])
      if element[0] == ':'
        main_window.color_on(3)
      elsif element[0] == '"' || element[0] == "'"
        main_window.color_on(4)
      elsif special_words.include?(element)
        main_window.color_on(2)
      end
      win.addstr("#{element} ")
      win.attron(Curses.color_pair(1))
    end
  end



  def main_window
    @main_window ||= Window.new
  end

  def initialize_app
    Curses.init_screen()
    Curses.start_color()
    Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
    Curses.noecho()

    main_window.color_on(1)
    main_window.buffer = []
  end

  def load_file
    file = File.open(ARGV.first, 'r')
    while (l = file.gets)
      main_window.buffer << l
    end
  end

  def run
    initialize_app
    load_file

    main_window.redraw_screen


    while 1
      key_input =
      case key_input
      when NEW_LINE
        main_window.handle_return_key(key_input, buffer)
      when LEFT
        main_window.move(:left)
      when RIGHT
        main_window.move(:right)
      when UP
        main_window.move(:up)
      when DOWN
        main_window.move(:down)
      when DC
        #main_window.setpos(main_window.cury, current_x - 1)
      when BACKSPACE
        main_window.backspace
      else

      end
    end
    main_window.close
  end
end

class Window
  attr_accessor :main_window, :buffer

  def initialize
    self.main_window = Curses::Window.new( 0, 0, 0, 0)
    main_window.keypad(true)
  end

  def handle_return_key(key_input, buffer)
    if key_input == 10
      buffer.insert(main_window.cury, '')
      old_pos = [main_window.cury, current_x]
      redraw_screen(main_window, buffer)
      main_window.setpos(old_pos.first + 1, old_pos.last)
    end
  end

  def get_character
    main_window.getch
  end

  def current_x
    main_window.curx
  end

  def current_y
    main_window.cury
  end

  def next_line
    buffer[current_y]
  end

  def previous_line
    buffer[current_y - 2]
  end

  def current_line
    buffer[current_y - 1]
  end

  def color_on(value)
    main_window.attron(Curses.color_pair(value))
  end

  def move(direction)
    case direction
    when :left
      current_x < 2 ? main_window.setpos(current_y, 0) : main_window.setpos(current_y, current_x - 1)
    when :right
      main_window.setpos(current_y, current_x + 1)
    when :up
      redraw_screen(main_window, buffer, 0, offset)
      current_y < 2 ? main_window.setpos(1, current_x) : main_window.setpos(current_y - 1, current_x)
    when :down
      redraw_screen(main_window, buffer, 0, offset)
      current_y >= buffer.size ? main_window.setpos(buffer.size, current_x) : main_window.setpos(current_y + 1, current_x)
    end
  end

  def backspace
    if current_x-1 >= 0
      buffer[main_window.cury-1][current_x-1] = ''
      old_pos = [main_window.cury, current_x]
      main_window.setpos(main_window.cury, 0)
      main_window.clrtoeol
      main_window.addstr(buffer[main_window.cury - 1])
      main_window.setpos(old_pos.first, old_pos.last- 1)
    end
  end

  def redraw_screen
    index = 0
    old_pos = [current_y, current_x]
    (0...52).each do |num|
      set_position(index + 1, 0)
      main_window.clrtoeol
      writeln()
      index += 1
    end
    set_position(old_pos.first, old_pos.last)
  end

  def set_position(x, y)
    previous_x = current_x
    previous_y = current_y
    main_window.setpos(x, y)
  end

  private

  def writeln
    main_window.refresh
    main_window.addstr("x")
  end

end

Editor.new.run

