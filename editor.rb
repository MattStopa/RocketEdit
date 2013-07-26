require 'curses'

class Buffer
  attr_accessor :data

  def initialize
    @data = []
  end

  def add_line(line)
    self.data << line
  end

  def set_line(line, line_number)
    self.data[line_number] = line
  end

  def at(number)
    data[number]
  end

  def insert_new_line(y, x)
    old_line = at(y)
    line1, line2 = '', nil
    if(x != 0)
      line1 = old_line[0...x]
      line2 = old_line[x..old_line.size]
      data.insert(y, line1)
      set_line(line2, y + 1)      
    else
      data.insert(y, line1)
    end


  end

end

class Editor
  attr_accessor :offset, :buffer

  NEW_LINE = 10
  LEFT = Curses::Key::LEFT
  RIGHT = Curses::Key::RIGHT
  UP = 259
  DOWN = Curses::Key::DOWN
  BACKSPACE = 127
  DC = Curses::Key::DC

  def initialize
    @offset = 0
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
    main_window.buffer = Buffer.new
  end

  def load_file
    return puts "No file specified" if(ARGV.first.nil?)
    file = File.open(ARGV.first, 'r')
    while (l = file.gets)
      main_window.buffer.add_line(l.split("\n").first)
    end
  end

  def run
    initialize_app
    load_file

    main_window.redraw_screen

    while 1
      key_input = main_window.get_character
      case key_input
      when NEW_LINE
        main_window.handle_return_key(key_input)
      when LEFT
        main_window.move(:left)
      when RIGHT
        main_window.move(:right)
      when 259
        main_window.move(:up)
      when DOWN
        main_window.move(:down)
      when DC
        #main_window.setpos(main_window.cury, current_x - 1)
      when BACKSPACE
        main_window.backspace
      else
        main_window.insert_text(key_input)
      end
    end
    main_window.close
  end
end

class Window
  attr_accessor :main_window, :buffer, :previous_x, :previous_y, :debug_line

  def initialize
    self.main_window = Curses::Window.new(0, 0, 0, 0)
    main_window.keypad(true)
  end

  def handle_return_key(key_input)
    if key_input == 10
      buffer.insert_new_line(main_window.cury, current_x)
      old_pos = [main_window.cury, current_x]
      redraw_screen
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
  alias :line_number :current_y

  def next_line
    buffer[current_y + 1]
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
      current_x < 2 ? set_position(0, line_number) : set_position(current_x - 1, line_number)
    when :right
      set_position(current_x + 1, current_y)
    when :up
      current_y < 2 ? set_position(current_x, 0) : set_position(current_x, current_y - 1)
    when :down
      current_y > 52 ? set_position(current_x, 52) : set_position(current_x, current_y + 1)
    end
    write_status_bar
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

  def insert_text(text)
    old_pos = [current_x, current_y]
    old_string = buffer.at(current_y)
    old_string += " " * (current_x - old_string.size) if(old_string.size < current_x)
    new_string = old_string.insert(current_x, text.to_s)
    buffer.set_line(new_string, current_y) 

    redraw_screen
    set_position(old_pos.first + 1, old_pos.last)
  end

  def redraw_screen
    main_window.clear
    visible_lines = (0...52)
    old_pos = [current_x, current_y]
    visible_lines.each do |num|
      writeln(buffer.at(current_y))
      move_to_next_line
      main_window.clrtoeol
    end
    write_status_bar
    set_position(old_pos.first, old_pos.last)
  end

  def move_to_next_line
    @lines ||= []
    @lines << current_y
    set_position(0, current_y + 1)
  end

  def set_position(x, y)
    self.previous_x = current_x
    self.previous_y = current_y
    main_window.setpos(y, x)
  end

  def set_to_previous_position
    set_position(previous_x, previous_y)
  end

  private

  def writeln(line)
    return if line == nil
    main_window.addstr(line)
  end

  def write_status_bar
    # set_position(0, 54)
    # main_window.clrtoeol
    # writeln("Line: #{previous_y + 1} | Column: #{previous_x + 1} | Debug: '#{debug_line}'...             ")
    # set_to_previous_position
    # self.debug_line = ""
  end
end

Editor.new.run

