require 'curses'

class Buffer
  attr_accessor :buffer

  def [](num)
  end
end

class Editor
  attr_accessor :offset, :buffer

  NEW_LINE = 10
  LEFT = Curses::Key::LEFT
  RIGHT = Curses::Key::RIGHT

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
        win.attron(Curses.color_pair(3))
      elsif element[0] == '"' || element[0] == "'"
        win.attron(Curses.color_pair(4))
      elsif special_words.include?(element)
        win.attron(Curses.color_pair(2))
      end
      win.addstr("#{element} ")
      win.attron(Curses.color_pair(1))
    end
  end

  def handle_return_key(x, win, buffer)
    if x == 10
      buffer.insert(win.cury, '')
      old_pos = [win.cury, win.curx]
      redraw_screen(win, buffer)
      win.setpos(old_pos.first + 1, old_pos.last)
    end
  end

  def move(win, buffer, direction, offset=0)
    current_line = buffer[win.cury - 1]
    previous_line = buffer[win.cury - 2]
    next_line = buffer[win.cury]
    case direction
    when :left
      win.curx == 0 || win.curx == 1 ? win.setpos(win.cury, 0) : win.setpos(win.cury, win.curx - 1)
    when :right
      win.setpos(win.cury, win.curx + 1)
      align_on_right(win, buffer, current_line)
    when :up
      redraw_screen(win, buffer, 0, offset)
      win.cury == 0 || win.cury == 1 ? win.setpos(1, win.curx) : win.setpos(win.cury - 1, win.curx)
      align_on_right(win, buffer, previous_line)
    when :down
      redraw_screen(win, buffer, 0, offset)
      win.cury >= buffer.size ? win.setpos(buffer.size, win.curx) : win.setpos(win.cury + 1, win.curx)
      align_on_right(win, buffer, next_line) if !(win.cury == buffer.size)
    end
  end

  def align_on_right(win, buffer, current_line)
     current_line.size < win.curx + 1 ? win.setpos(win.cury, current_line.size - 1) : win.setpos(win.cury, win.curx)
  end

  def redraw_screen(win, buffer, start=0, buffer_offset=0)
    index = 0
    old_pos = [win.cury, win.curx]
    (buffer_offset..buffer_offset+52).each do |num|
      win.setpos(index + 1, 0)
      win.clrtoeol
      writeln(win, num, buffer[num], buffer)
      index += 1
    end
    win.setpos(old_pos.first, old_pos.last)

  end

  def main_window
    @window ||= Curses::Window.new( 0, 0, 0, 0)
  end

  def initialize_app
    Curses.init_screen()
    Curses.start_color()
    Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
    Curses.noecho()

    main_window.attron(Curses.color_pair(1));
    main_window.keypad(true)
    self.buffer = []
  end

  def load_file
    file = File.open(ARGV.first, 'r')
    while (l = file.gets)
      self.buffer << l
    end
  end

  def run
    initialize_app
    load_file

    redraw_screen(main_window, buffer)
    main_window.refresh

    lines = buffer.count

    while 1
      x = main_window.getch
      case x
      when NEW_LINE #new line
        handle_return_key(x, main_window, buffer)
      when LEFT
        move(main_window, buffer, :left)
      when Curses::Key::RIGHT
        move(main_window, buffer, :right)
      when Curses::Key::UP
        self.offset = offset - 1 if main_window.cury == 1 && offset > 0
        move(main_window, buffer, :up, offset)
      when Curses::Key::DOWN
        self.offset = offset + 1 if main_window.cury > 50
        move(main_window, buffer, :down, offset)
      when Curses::Key::DC
        main_window.setpos(main_window.cury, main_window.curx - 1)
      when 127 #backspace
        if main_window.curx-1 >= 0
        	buffer[main_window.cury-1][main_window.curx-1] = ''
        	old_pos = [main_window.cury, main_window.curx]
        	main_window.setpos(main_window.cury, 0)
        	main_window.clrtoeol
        	main_window.addstr(buffer[main_window.cury - 1])
        	main_window.setpos(old_pos.first, old_pos.last- 1)
        end
      else
        buffer[lines] = "" if buffer[lines] == nil
        buffer[main_window.cury + offset - 1].insert(main_window.curx, x.to_s)
        old_pos = [main_window.cury, main_window.curx]
        main_window.setpos(main_window.cury, 0)
        writeln(main_window, (main_window.cury + offset - 1), buffer[main_window.cury + offset - 1], buffer)
        main_window.setpos(old_pos.first, old_pos.last + 1)
      end
    end
    main_window.close
  end
end

Editor.new.run

