require 'set'

class Cube
  class Face
    def initialize(face=nil)
      if face.nil?
        s = Set.new(0..15)
        @state = [[s.clone, s.clone, s.clone, s.clone],
                  [s.clone, s.clone, s.clone, s.clone],
                  [s.clone, s.clone, s.clone, s.clone],
                  [s.clone, s.clone, s.clone, s.clone]]
        @orientation = 0
      else
        @state = face.state.clone
        @orientation = face.orientation
      end
    end
    attr_reader :state
    attr_reader :orientation

    def display_strings(orientation=0,fixed=true)
      
      [ '/-------\\',
        *display_elements(elements(orientation).map {|x| format_cell(fixed, x)} ),
        '\\-------/']
    end

    def display_elements(elements)
      ["|#{elements.shift} #{elements.shift} #{elements.shift} #{elements.shift}|",
       "|#{elements.shift} #{elements.shift} #{elements.shift} #{elements.shift}|",
       "|#{elements.shift} #{elements.shift} #{elements.shift} #{elements.shift}|",
       "|#{elements.shift} #{elements.shift} #{elements.shift} #{elements.shift}|"]
    end

    def elements(orientation)
      res = []
      orientation = (orientation + @orientation) % 4
      (0..3).each { |r| res.push(*get_row(r)) }
      res
    end
    
    def format_cell(fixed, a_cell)
      if fixed
        format_cell_fixed(a_cell)
      else
        format_cell_pos(a_cell)
      end
    end
    
    def format_cell_fixed(a_cell)
      case a_cell.size
      when 0
        '!'
      when 1
        a_cell.to_a[0].to_s(16)
      else
        '?'
      end
    end

    def format_cell_pos(a_cell)
      case a_cell.size
      when 0
        '!'
      when 1
        'x'
      when 16
        '*'
      else
        a_cell.size.to_s(16)
      end
    end

    def rotate(n=1)
      @orientation = (@orientation + n) % 4
      self
    end

    def get_cell(r, c)
      get_row(r)[c]
    end
    
    def get_row(n, orientation=0)
      orientation = (orientation + @orientation) % 4
      case orientation
      when 0
        @state[n]
      when 1
        (0..3).map { |x| @state[3 - x][n] }.to_a
      when 2
        @state[3 - n].reverse
      when 3
        (0..3).map { |x| @state[x][3 - n] }.to_a
      end
    end

    def get_col(n, orientation=0)
      orientation = (orientation + @orientation) % 4
      case orientation
      when 0
        (0..3).map { |x| @state[x][n] }.to_a
      when 1
        @state[3 - n].reverse
      when 2
        (0..3).map { |x| @state[3 - x][3 - n] }.to_a
      when 3
        @state[n]
      end
    end

    def to_s(orientation=0, fixed=true)
      display_strings(orientation, fixed).reduce { |a, b| a + "\n" + b }
    end

    def inspect
      to_s
    end
  end

  def initialize
    @f = Face.new
    @b = Face.new
    @u = Face.new
    @d = Face.new
    @l = Face.new
    @r = Face.new
  end

  def to_s(fixed=true)
    us = @u.display_strings(0, fixed)
    ds = @d.display_strings(0, fixed)
    fs = @f.display_strings(0, fixed)
    bs = @b.display_strings(0, fixed)
    ls = @l.display_strings(0, fixed)
    rs = @r.display_strings(0, fixed)
    6.times { puts "          " + us.shift }
    6.times { puts ls.shift + ' ' + fs.shift + ' ' + rs.shift + ' ' + bs.shift }
    6.times { puts "          " + ds.shift }
  end

  def get_linked_rows(r,c)
    res = []
    [@f, @l, @r, @b].each {|f| f.get_row(r).each { |e| res << e } }
    res.delete_at(c)
    res
  end

  def get_linked_cols(r,c)
    res = []
    [@f, @u, @d].each {|f| f.get_col(c).each { |e| res << e } }
    @b.get_col(3 - c).each { |e| res << e }
    res.delete_at(r)
    res
  end

  def get_other_face_cells(r,c)
    res = []
    (0..3).each {|x| @f.get_row(x).each { |e| res << e } }
    res.delete_at( r * 4 + c )
    res
  end
    
  def set(r, c, val)
    cell = @f.get_cell(r, c)
    cell.reject! { |x| x != val }
    [ get_linked_rows(r,c), get_linked_cols(r,c), get_other_face_cells(r,c)].each do |linked|
      linked.each { |c| c.delete(val) }
    end
    self
  end

  def check(r, c, val)
    cell = @f.get_cell(r, c).clone
    if !cell.include?(val)
      return false
    end
    res = true
    [ get_linked_rows(r,c), get_linked_cols(r,c), get_other_face_cells(r,c)].each do |linked|
      res = res & check_linked(linked, val)
    end
    res
  end
  
  def check_linked(linked, val)
    vals = Set.new
    vals.add (val)
    linked.each do |cell|
      cell = cell.clone
      if cell.size == 1 && cell.include?(val)
        return false
      end
      cell.delete(val)
      if cell.size == 1
        if vals.include?(cell.to_a[0])
          return false
        else
          vals.add(cell.to_a[0])
        end
      end
    end
    true
  end

  def possible(r, c)
    cell = @f.get_cell(r, c).clone
  end
  
  def rotate_f_to_l(n=1)
    n.times do
      tmp = @l
      @l = @f
      @f = @r
      @r = @b
      @b = tmp
      @u.rotate
      @d.rotate(-1)
    end
    self
  end
  
  def rotate_u_to_f(n=1)
    n.times do
      tmp = @f
      @f = @u
      @u = @b
      @b = @d
      @d = tmp
      @u.rotate(2)
      @b.rotate(2)
      @l.rotate
      @r.rotate(-1)
    end
    self
  end

  def rotate_clockwise
    rotate_f_to_l
    rotate_u_to_f
    rotate_f_to_l(3)
  end
    
  def self.generate()
    seed = nil
    res = nil
    count = 0
    c = nil
    stats = Array.new(97,0)
    while(seed == nil)
      c = Cube.new
      c.set_face(ORDERED_SQUARE)
      (seed, res) = c.construct
      stats[c.fixed_cells] += 1
      count += 1
      if (count % 1000) == 0
        puts "#{count} attempts."
      end
    end

    puts "Cube #{seed} after #{count} attempts."
    c
  end

  def fixed_cells
    total = 0
    [@l, @f, @r, @b, @u, @d].each { |f|
      (0..3).each { |r|
        row = f.get_row(r)
        (0..3).each { |c|
          total += 1 if row[c].size == 1
        }
      }
    }
    total
  end
    
  def self.gen_test(seed=nil)
    seed = Random.new.seed if seed.nil?
    c = Cube.new
    c.construct(seed)
    puts "Seed = #{seed}"
    c
  end
  
  def construct(seed=nil)
    r = if seed.nil?
          Random.new
        else
          Random.new(seed)
        end
    seed = r.seed
    magic_square
    return [nil, nil] unless construct_faces(r)
    rotate_u_to_f
    return [nil, nil] unless construct_faces(r)
    [seed, self]
  end

  def construct_faces(prng)
    (0..3).each do
      return false unless construct_face(prng)
      rotate_f_to_l
    end
    true
  end

  def construct_face(prng)
    (0..3).each do |r|
      (0..3).each do |c|
        pos = possible(r,c).to_a
        case pos.size
        when 0
          return false
        when 1
          next
        else
          while (pos.size > 0)
            v = prng.rand(pos.size)
            if check(r, c, pos[v])
              set(r, c, pos[v])
              break
            else
              pos.delete_at(v)
            end
            if pos.size == 1 && !check(r,c, pos[0])
              return false
            end
          end
        end
      end
    end
    true
  end

  MAGIC_SQUARE = [[0, 13, 7, 10],
                  [14, 3, 9, 4],
                  [11, 6, 12, 1],
                  [5, 8, 2, 15]]
  
  ORDERED_SQUARE = [[0, 1, 2, 3],
                    [4, 5, 6, 7],
                    [8, 9, 10, 11],
                    [12, 13, 14, 15, 16]]

  def all_orientations
    4.times do
      yield
      rotate_clockwise
    end
  end
  
  def all_faces
    4.times do
      yield
      rotate_f_to_l
    end
    rotate_u_to_f
    yield
    rotate_u_to_f(2)
    yield
  end
    
  def attempt_set_face(square)
    all_faces do
      all_orientations do
        return true if check_face(square)
      end
    end
    false
  end
  
      
  def set_face(square)
    (0..3).each do |r|
      (0..3).each do |c|
        if check(r, c, square[r][c])
          set(r, c, square[r][c])
        end
      end
    end
    self
  end
      
  def check_face(square)
    (0..3).each do |r|
      (0..3).each do |c|
        unless check(r, c, square[r][c])
          return false
        end
      end
    end
    true
  end
      
  def inspect
    to_s
  end
end

