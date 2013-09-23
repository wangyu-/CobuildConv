# COBUILD 用ライブラリ

=begin
履歴:
  v1.00 2003-06-28 by nomad
    公開
  v1.10 2004-01-14 by nomad
    特殊文字の扱いを若干変更
    メソッド名を変更
      read() -> getc()、readFlag -> getFlag
    CobuildDecoderDebug
      標準出力にすべての文字列とデータを出力するように変更
  v1.20 2004-01-31 by nomad
    GRAPHICS のデータを unicode として処理するように修正
      GRAPHICS -> UNICODE, Gtable -> Utable
    不明文字の値を2進数でなく10進数で出力するように変更
  v1.30 2004-02-17 by nomad
    Mac 環境への対応 ('L*' -> 'V*'、'S*' -> 'v*'、unpack のパッチ)
  v1.31 2004-02-26 by nomad
    schwa と 1/3 の「;」のつけ忘れを修正
    printUnknown、printFlags で出力先を指定

権利: Copyright (C) 2003-2004, nomad
      オープンソース扱い
====
クラス構成

  class CobuildDecoder           データ解読
    class CobuildDecoderDebug < CobuildDecoder  デバッグ用

  class CobuildFile < File       辞書ファイル
    include Enumerable
  class CobuildImageFile < File  画像ファイル
    include Enumerable

=end

# Mac OS X 10.2 付属の ruby 1.6.7 のバグへの対処 ('V*' がきかない)
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

# データ解読
class CobuildDecoder

  Ctable = {
    # 英小文字
    1 => 'a', 2 => 'b', 3 => 'c', 4 => 'd',
    5 => 'e', 6 => 'f', 7 => 'g', 8 => 'h', 9 => 'i',
    10 => 'j', 11 => 'k', 12 => 'l', 13 => 'm', 14 => 'n',
    15 => 'o', 16 => 'p', 17 => 'q', 18 => 'r', 19 => 's',
    20 => 't', 21 => 'u', 22 => 'v', 23 => 'w', 24 => 'x',
    25 => 'y', 26 => 'z',

    # 常用記号
    32 => ' ', 33 => '.', 34 => '<', 35 => '>',
    36 => ',', 37 => ';', 38 => '-',

    # 後続文字とあわせて 1 文字
    40 => '&grave;', 41 => '&acute;', 42 => '&circ;',
    43 => '&tilde;', 44 => '&uml;', 49 => '&cedil;',
    52 => 'GREEK',
    59 => 'SYMBOL',  61 => 'UPCASE', 62 => 'SPECIAL',

    # うしろにデータ 4 文字分 (3 バイト)
    63 => 'UNICODE'

  }

=begin
GRAPHICS=0C71D0&gt;013  tick <-- errata
{tilde;UNKNOWN=101110}   3

開始日時: 2004-01-14 21:28:16
Wordbank を出力しています...
18922/18922
==== Unknown chars ====
{UNKNOWN=101110}    11
{UNKNOWN=101111}    78
{UNKNOWN=110010}   102
{UNKNOWN=110011}     1
{UNKNOWN=111001}     6
{UNKNOWN=111100}     1
終了日時: 2004-01-14 21:37:01
処理時間: 00:08:45

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

    # ???? ほとんど未確認
    26 => ':', 27 => ';', 28 => '&lt;', 29 => '=', 30 => '&gt;',
    31 => '?', 32 => '@', 33 => '[', 34 => '\\', 35 => ']',
    36 => '^', 37 => '_', 38 => '`', 39 => '{', 40 => '|',
    41 => '}', 42 => '~',
    43 => '?? '	# 編集ミス? or bullet?
  }

  # SYMBOL
  Symtable = {
     4 => '&sect;',         # セクション記号 (本当は &#134) 000100
    10 => '"', 11 => '"',   # 引用符 "..."
    12 => '* ',             # bullet 001100
    13 => ' -- ',           # ??? 
    14 => ' --- ',          # 長いダッシュ
    15 => '&trade;',        # 商標 001111
    18 => '&cent;',         # セント記号 010010
    19 => '&pound;',        # ポンド記号
    24 => '&copy;',         # 著作権記号 011000
    28 => '&reg;',          # 登録商標   011100
    29 => '&deg;',          # 角度記号
    31 => '&sup2;',         # 上付きの2 011111
    32 => '&sup3;',         # 上付きの3 100000
    36 => '&sup1;',         # 上付きの1 100100
    40 => '&frac12;',       # 分数 1/2  101000
    43 => '&times;',        # 乗算記号  101011
    44 => '&divide;'        # 除算記号  101100
  }

  # UNICODE
  Utable = {
    0x0259 => '&#x0259;',   # schwa
    0x2070 => '<E.0>',      # superscript 0 上付き数字
    0x2074 => '<E.4>',      # superscript 4
    0x2075 => '<E.5>',      # superscript 5
    0x2079 => '<E.9>',      # superscript 9
    0x2153 => '&xFrac13;',  # 分数 1/3
    0x2192 => '→',         # rightwards arrow
    0x2660 => '&spades;',   # トランプのスペード
    0x2663 => '&clubs;',    # トランプのクラブ
    0x2665 => '&hearts;',   # トランプのハート
    0x2666 => '&diams;',    # トランプのダイヤ
    0x266D => '♭',         # music flat
    0x266F => '♯',         # music sharp
    0x3003 => '〃',         # ditto
  }

  # GREEK
  Greektable = {
    16 => 'π',     # 小文字の pi (&pi;)
    53 => 'Φ',     # 大文字の phi (&Phi;)
  }

  def initialize
    @unknown = Hash::new(0)
  end

  # データを設定する。以後、操作はこのデータに対しておこなう
  def setData(s)
    @s = s
    @sp = 0
    @counter = 0
  end

  # 1文字(6ビット)を取得して、その数値を返す
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

  # 入力バイト位置を移動する
  def next(n = 1)
    @sp += n
  end

  # 現在位置のバイト値を返す
  def char()
    @s[@sp]
  end

  # 現在位置以降を文字列データとみなして解読し、通常の文字列として返す
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
          a.push('〓')      # ゲタ
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

  # 1 バイト読み込んで、その数値を返す
  def getc()
    @counter = 0
    c = @s[@sp]
    @sp += 1
    c
  end

  # フラグを読み込んで、その数値を返す
  #  (CobuildDecoderDebug 用、このクラスでは getc() と同じ動作)
  def getFlag(tag = '')
    @counter = 0
    c = @s[@sp]
    @sp += 1
    c
  end

  # n バイト読み込んで、その文字列を返す
  # バイト数の指定がなければ 1 バイトだけ読み込む
  def readStr(n = 1)
    @counter = 0
    s = @s[@sp, n]
    @sp += n
    s
  end

  # 不明文字を出力する
  def printUnknown(out = STDOUT)
    unless @unknown.empty?
      out.puts '==== Unknown chars ===='
      @unknown.sort.each { |k, v|
        out.printf("%s  %4d\n", k, v)
      }
    end
  end

end

# デバッグ用
class CobuildDecoderDebug < CobuildDecoder
# 次の形式で文字列およびデータを標準出力にも出力する
#  バイト読み込み  {XX}
#  フラグ          [tagname:XX]

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

  # フラグ一覧を出力する
  def printFlags(out = STDOUT)
    out.puts '==== Flags ===='
    @h.sort.each { |k, v|
      out.printf("%s %6d\n", k, v)
    }
  end

end

# データファイル (.trd)
class CobuildFile < File
  include Enumerable

  # ヘッダ情報を読み込む
  #   new の後、必ず実行する必要がある
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

  # レコードインデックスを作成する
  #   getRec と each を使用する場合、事前に実行しておく必要がある
  #   init 内で実行しておいてもよさそうだが...
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

  # レコード数を返す
  def recCount
    return @entryCount
  end

  # レコードを返す
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

# 画像ファイル (.mbx)
class CobuildImageFile < File
  include Enumerable

  attr_reader :dataCount

  # ヘッダ情報を読み込み、インデックスを作成する
  #   new の後、必ず実行する必要がある
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

  # 画像データ (gif) を返す
  def getImage(num)
    # @t[0] と @t[@t.size - 1] はダミー?
    if (num < 1) || (num >= @t.size - 1)
      return ''
    else
      seek(@dataPos + @t[num] + 1)      # +1 で先頭 1 バイト読み飛ばし
      read(@t[num + 1] - @t[num] - 1)
    end
  end

  def each
    @dataCount.times { |i|
      yield getImage(i)
    }
  end

end
