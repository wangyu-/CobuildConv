# COBUILD �p���C�u����

=begin
����:
  v1.00 2003-06-28 by nomad
    ���J
  v1.10 2004-01-14 by nomad
    ���ꕶ���̈������኱�ύX
    ���\�b�h����ύX
      read() -> getc()�AreadFlag -> getFlag
    CobuildDecoderDebug
      �W���o�͂ɂ��ׂĂ̕�����ƃf�[�^���o�͂���悤�ɕύX
  v1.20 2004-01-31 by nomad
    GRAPHICS �̃f�[�^�� unicode �Ƃ��ď�������悤�ɏC��
      GRAPHICS -> UNICODE, Gtable -> Utable
    �s�������̒l��2�i���łȂ�10�i���ŏo�͂���悤�ɕύX
  v1.30 2004-02-17 by nomad
    Mac ���ւ̑Ή� ('L*' -> 'V*'�A'S*' -> 'v*'�Aunpack �̃p�b�`)
  v1.31 2004-02-26 by nomad
    schwa �� 1/3 �́u;�v�̂��Y����C��
    printUnknown�AprintFlags �ŏo�͐���w��

����: Copyright (C) 2003-2004, nomad
      �I�[�v���\�[�X����
====
�N���X�\��

  class CobuildDecoder           �f�[�^���
    class CobuildDecoderDebug < CobuildDecoder  �f�o�b�O�p

  class CobuildFile < File       �����t�@�C��
    include Enumerable
  class CobuildImageFile < File  �摜�t�@�C��
    include Enumerable

=end

# Mac OS X 10.2 �t���� ruby 1.6.7 �̃o�O�ւ̑Ώ� ('V*' �������Ȃ�)
class String
  alias unpack_org unpack
  def unpack(template)
    case template
    when 'V*', 'L*'
      self.scan(/..../nm).collect{|x| x.reverse.unpack('N')[0] }
    when 'v*', 'S*'
      self.scan(/../nm).collect{|x| x.reverse.unpack('n')[0] }
    else
      unpack_org(template)
    end
  end
end

# �f�[�^���
class CobuildDecoder

  Ctable = {
    # �p������
    1 => 'a', 2 => 'b', 3 => 'c', 4 => 'd',
    5 => 'e', 6 => 'f', 7 => 'g', 8 => 'h', 9 => 'i',
    10 => 'j', 11 => 'k', 12 => 'l', 13 => 'm', 14 => 'n',
    15 => 'o', 16 => 'p', 17 => 'q', 18 => 'r', 19 => 's',
    20 => 't', 21 => 'u', 22 => 'v', 23 => 'w', 24 => 'x',
    25 => 'y', 26 => 'z',

    # ��p�L��
    32 => ' ', 33 => '.', 34 => '<', 35 => '>',
    36 => ',', 37 => ';', 38 => '-',

    # �㑱�����Ƃ��킹�� 1 ����
    40 => '&grave;', 41 => '&acute;', 42 => '&circ;',
    43 => '&tilde;', 44 => '&uml;', 49 => '&cedil;',
    52 => 'GREEK',
    59 => 'SYMBOL',  61 => 'UPCASE', 62 => 'SPECIAL',

    # ������Ƀf�[�^ 4 ������ (3 �o�C�g)
    63 => 'UNICODE'

  }

=begin
GRAPHICS=0C71D0&gt;013  tick <-- errata
{tilde;UNKNOWN=101110}   3

�J�n����: 2004-01-14 21:28:16
Wordbank ���o�͂��Ă��܂�...
18922/18922
==== Unknown chars ====
{UNKNOWN=101110}    11
{UNKNOWN=101111}    78
{UNKNOWN=110010}   102
{UNKNOWN=110011}     1
{UNKNOWN=111001}     6
{UNKNOWN=111100}     1
�I������: 2004-01-14 21:37:01
��������: 00:08:45

<UNKNOWN=101110>    12  after &slash; 'O' 46
<UNKNOWN=101111>   101  &ring; ? 47
<UNKNOWN=110010>   119  &slash;  50
<UNKNOWN=110011>     1  ss??       51
<UNKNOWN=111001>     6  after &ring; 57 '
<UNKNOWN=111100>     1  after &ring;  60 ??
=end

  # SPECIAL
  Stable = {
    1 => '!', 2 => '"', 3 => '#', 4 => '$', 5 => '%',
    6 => '&amp;', 7 => "'", 8 => '(', 9 => ')', 10 => '*',
    11 => '+',  ####  12 => ',', 13 => '-', 14 => '.', # ???
    15 => '/',

    16 => '0', 17 => '1', 18 => '2', 19 => '3', 20 => '4',
    21 => '5', 22 => '6', 23 => '7', 24 => '8', 25 => '9',

    # ???? �قƂ�ǖ��m�F
    26 => ':', 27 => ';', 28 => '&lt;', 29 => '=', 30 => '&gt;',
    31 => '?', 32 => '@', 33 => '[', 34 => '\\', 35 => ']',
    36 => '^', 37 => '_', 38 => '`', 39 => '{', 40 => '|',
    41 => '}', 42 => '~',
    43 => '?? '	# �ҏW�~�X? or bullet?
  }

  # SYMBOL
  Symtable = {
     4 => '&sect;',         # �Z�N�V�����L�� (�{���� &#134) 000100
    10 => '"', 11 => '"',   # ���p�� "..."
    12 => '* ',             # bullet 001100
    13 => ' -- ',           # ??? 
    14 => ' --- ',          # �����_�b�V��
    15 => '&trade;',        # ���W 001111
    18 => '&cent;',         # �Z���g�L�� 010010
    19 => '&pound;',        # �|���h�L��
    24 => '&copy;',         # ���쌠�L�� 011000
    28 => '&reg;',          # �o�^���W   011100
    29 => '&deg;',          # �p�x�L��
    31 => '&sup2;',         # ��t����2 011111
    32 => '&sup3;',         # ��t����3 100000
    36 => '&sup1;',         # ��t����1 100100
    40 => '&frac12;',       # ���� 1/2  101000
    43 => '&times;',        # ��Z�L��  101011
    44 => '&divide;'        # ���Z�L��  101100
  }

  # UNICODE
  Utable = {
    0x0259 => '&#x0259;',   # schwa
    0x2070 => '<E.0>',      # superscript 0 ��t������
    0x2074 => '<E.4>',      # superscript 4
    0x2075 => '<E.5>',      # superscript 5
    0x2079 => '<E.9>',      # superscript 9
    0x2153 => '&xFrac13;',  # ���� 1/3
    0x2192 => '��',         # rightwards arrow
    0x2660 => '&spades;',   # �g�����v�̃X�y�[�h
    0x2663 => '&clubs;',    # �g�����v�̃N���u
    0x2665 => '&hearts;',   # �g�����v�̃n�[�g
    0x2666 => '&diams;',    # �g�����v�̃_�C��
    0x266D => '��',         # music flat
    0x266F => '��',         # music sharp
    0x3003 => '�V',         # ditto
  }

  # GREEK
  Greektable = {
    16 => '��',     # �������� pi (&pi;)
    53 => '��',     # �啶���� phi (&Phi;)
  }

  def initialize
    @unknown = Hash::new(0)
  end

  # �f�[�^��ݒ肷��B�Ȍ�A����͂��̃f�[�^�ɑ΂��Ă����Ȃ�
  def setData(s)
    @s = s
    @sp = 0
    @counter = 0
  end

  # 1����(6�r�b�g)���擾���āA���̐��l��Ԃ�
  def getBits()
    case @counter % 4
    when 0
      return nil if @sp >= @s.size
      c = @s[@sp] >> 2
      @r = ( @s[@sp] & 0x03 )
      @sp += 1
    when 1
      return nil if @sp >= @s.size
      c = ( @r << 4 ) + ( @s[@sp] >> 4 )
      @r = ( @s[@sp] & 0x0F )
      @sp += 1
    when 2
      return nil if @sp >= @s.size
      c = ( @r << 2 ) + ( @s[@sp] >> 6 )
      @r = ( @s[@sp] & 0x3F )
      @sp += 1
    when 3
      c = @r
    end
    @counter += 1
    c
  end

  # ���̓o�C�g�ʒu���ړ�����
  def next(n = 1)
    @sp += n
  end

  # ���݈ʒu�̃o�C�g�l��Ԃ�
  def char()
    @s[@sp]
  end

  # ���݈ʒu�ȍ~�𕶎���f�[�^�Ƃ݂Ȃ��ĉ�ǂ��A�ʏ�̕�����Ƃ��ĕԂ�
  def decode()
    @counter = 0
    a = []

    while b = getBits

      if b == 0     # '000000'
        return a.join
      end

      case Ctable[b]
      when 'UPCASE'
        b = getBits
        a.push((b + 33).chr)  # ?A + ( b - 32 )
      when 'SPECIAL'
        b = getBits
        if Stable.key?(b)
          a.push(Stable[b])
        else
          s = sprintf("{SPECIAL=%d}", b)
          a.push(s)
          @unknown[s] += 1
        end
      when 'SYMBOL'
        b = getBits
        if Symtable.key?(b)
          a.push(Symtable[b])
        else
          s = sprintf("{SYMBOL=%d}", b)
          a.push(s)
          @unknown[s] += 1
        end
      when 'UNICODE'
        b1 = getBits
        b2 = getBits
        b3 = getBits
        b4 = getBits
        b = ((b1 - 1) << 12) + ((b2 - 1) << 8) + ((b3 - 1) << 4) + (b4 - 1)
        if Utable.key?(b)
          a.push(Utable[b])
        else
          s = sprintf("{UNICODE=%04X}", b)
#          a.push(s)
          a.push('��')      # �Q�^
          @unknown[s] += 1  # ???
        end
      when 'GREEK'
        b = getBits
        if Greektable.key?(b)
          a.push(Greektable[b])
        else
          s = sprintf("{GREEK=%d}", b)
          a.push(s)
          @unknown[s] += 1
        end
      when nil
        s = sprintf("{UNKNOWN=%d}", b)
        a.push(s)
        @unknown[s] += 1
      else
        a.push(Ctable[b])
      end

    end

    if a.empty?
      nil
    else
      a.join
    end
  end

  # 1 �o�C�g�ǂݍ���ŁA���̐��l��Ԃ�
  def getc()
    @counter = 0
    c = @s[@sp]
    @sp += 1
    c
  end

  # �t���O��ǂݍ���ŁA���̐��l��Ԃ�
  #  (CobuildDecoderDebug �p�A���̃N���X�ł� getc() �Ɠ�������)
  def getFlag(tag = '')
    @counter = 0
    c = @s[@sp]
    @sp += 1
    c
  end

  # n �o�C�g�ǂݍ���ŁA���̕������Ԃ�
  # �o�C�g���̎w�肪�Ȃ���� 1 �o�C�g�����ǂݍ���
  def readStr(n = 1)
    @counter = 0
    s = @s[@sp, n]
    @sp += n
    s
  end

  # �s���������o�͂���
  def printUnknown(out = STDOUT)
    unless @unknown.empty?
      out.puts '==== Unknown chars ===='
      @unknown.sort.each { |k, v|
        out.printf("%s  %4d\n", k, v)
      }
    end
  end

end

# �f�o�b�O�p
class CobuildDecoderDebug < CobuildDecoder
# ���̌`���ŕ����񂨂�уf�[�^��W���o�͂ɂ��o�͂���
#  �o�C�g�ǂݍ���  {XX}
#  �t���O          [tagname:XX]

  def initialize
    super
    @h = Hash::new(0)
  end

  def decode()
    s = super
    puts s
    s
  end

  def getc()
    c = super
    printf("{%02X}\n", c)
    c
  end

  def getFlag(tag = '')
    c = super
    x = sprintf('[%s:%02X]', tag, c)
    @h[x] += 1
    puts x
    c
  end

  def readStr(n = 1)
    s = super
    h, = s.unpack('H*')
    print '{', h, '}', "\n"
    s
  end

  # �t���O�ꗗ���o�͂���
  def printFlags(out = STDOUT)
    out.puts '==== Flags ===='
    @h.sort.each { |k, v|
      out.printf("%s %6d\n", k, v)
    }
  end

end

# �f�[�^�t�@�C�� (.trd)
class CobuildFile < File
  include Enumerable

  # �w�b�_����ǂݍ���
  #   new �̌�A�K�����s����K�v������
  def init
    binmode
    read(64)
    a = read(64).unpack('V*')
    @entryCount = a[4]
    @indexBaseCount = a[6]
    @indexOffsetCount = a[7]
    @pos1 = a[8]
    @indexPos = a[9]
    @bodyPos = a[10]
    @pos0 = 0x80
  end

  # ���R�[�h�C���f�b�N�X���쐬����
  #   getRec �� each ���g�p����ꍇ�A���O�Ɏ��s���Ă����K�v������
  #   init ���Ŏ��s���Ă����Ă��悳��������...
  def makeIndex
    seek(@indexPos)
    bases = read(@indexBaseCount * 4).unpack('V*')
    @index = []
    bases.size.times { |i|
      offsets = read(64 * 2).unpack('v*')
      offsets.each { |v|
        if @index.size < @indexOffsetCount
          @index.push(@bodyPos + bases[i] + v * 4)
        end
      }
    }

#  @index.each { |v|
#    $stdout.printf("%08X %10d\n", v, v)
#  }
  end

  # ���R�[�h����Ԃ�
  def recCount
    return @entryCount
  end

  # ���R�[�h��Ԃ�
  def getRec(n)
    if n >= 0 && n < @entryCount
      seek(@index[n])
      return read(@index[n + 1] - @index[n])
    else
      return ''
    end
  end

  def each
    @entryCount.times { |i|
      yield getRec(i)
    }
  end

end

# �摜�t�@�C�� (.mbx)
class CobuildImageFile < File
  include Enumerable

  attr_reader :dataCount

  # �w�b�_����ǂݍ��݁A�C���f�b�N�X���쐬����
  #   new �̌�A�K�����s����K�v������
  def init
    dummy = read(80)
    tblCount, indexCount, @dataCount, = read(16).unpack('V*')
#Kernel.printf("%d %d %d\n", tblCount, indexCount, @dataCount)
    tblPos, indexPos, @dataPos, = read(16).unpack('V*')

    @t = []
    seek(indexPos)
    indexCount.times { |n|
      @t[n], = read(4).unpack('V*')
    }

#@t.each_index { |n|
#  Kernel.print n, ' ', @t[n], "\n"
#}

  end

  # �摜�f�[�^ (gif) ��Ԃ�
  def getImage(num)
    # @t[0] �� @t[@t.size - 1] �̓_�~�[?
    if (num < 1) || (num >= @t.size - 1)
      return ''
    else
      seek(@dataPos + @t[num] + 1)      # +1 �Ő擪 1 �o�C�g�ǂݔ�΂�
      read(@t[num + 1] - @t[num] - 1)
    end
  end

  def each
    @dataCount.times { |i|
      yield getImage(i)
    }
  end

end
