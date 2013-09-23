# ENCoding: UTF-8
#!/user/local/bin/ruby -Ks
#aaa
#testing
def showHelp; scrName = File::basename($0.gsub(/\\/, '/'));
puts <<"================================================"
概要: COBUILD の EBStudio 用入力ファイルを作成する
構文: ruby -Ks #{scrName} [<options>] <inDir> [<outDir>]
  <options>
    -standard  Wordbank 以外を変換する (既定値)
    -wordbank  Wordbank のみを変換する
  <inDir>   .trd ファイルのあるディレクトリ
  <outDir>  出力ディレクトリ (指定なしならカレントディレクトリ)
例:
* COBUILD CD-ROM v1.0 (X:) から作成する
  ruby -Ks #{scrName} X:\\ D:\\EPWING\\Cobuild
* COBUILD CD-ROM v2.0/3.0 (X:) から Wordbank を作成する
  ruby -Ks #{scrName} -wordbank X:\\DATA D:\\EPWING\\Cobuild
================================================
end
=begin
出力: *.html  EBStudio 入力ファイル
      *.ebs   EBStudio 作業環境定義ファイル
履歴:
  v1.00 2003-06-28 by nomad
    公開
  v1.10 2003-07-15 by nomad
    Wordbank に対応 (-wordbank オプション)
    CD-ROM v2.0 で派生形の索引が作成されないバグを修正
    CD-ROM v1.0 で派生形の後方一致索引が正しく作成されないバグを修正
    著作権ファイルを追加
    外字ファイルを出力先にコピー
    その他
  v1.11 2003-07-29 by nomad
    CD-ROM v2.0 のファイル名のミスを修正 (hcp_en_cc3.trd -> hcp_en-cc3.trd など)
  v1.12 2003-07-30 by nomad
    ファイル名の修正もれ (hcp_en_cc3.mbx -> hcp_en-cc3.mbx)
  v1.20 2004-01-18 by nomad
    CD-ROM v3.0 に対応
    InPath を絶対パスで出力するように修正
  v1.30 2004-02-04 by nomad
    Resource Pack に対応
    Wordbank を 1 書籍にする ebs を標準にし、2 書籍にする ebs も出力
    Wordbank 以外の外字に完全対応
  v1.31 2004-02-17 by nomad
    Mac 環境で実行できるよう修正
  v1.32 2004-02-26 by nomad
    &Frac13; が外字に変換されなかったのを修正
    文末に文字参照 (&...;) がくると外字に変換されない場合があったのを修正
    Resource Pack の記号、ipa_schwa に対応
    tick mark の外字を追加
権利: Copyright (C) 2003-2004, nomad
      オープンソース扱い
=end

  # ライブラリのロード
  scrPath = File::dirname($0.gsub(/\\/, '/'))
  scrName = File::basename($0.gsub(/\\/, '/'))
  $LOAD_PATH.unshift(scrPath)     # スクリプトパスをロードパスに追加

  begin
    libName = 'CobuildLib.rb'
    require libName
  rescue LoadError => e
    STDERR.puts e.message
    STDERR.puts "対処: #{scrName} と #{libName} のあるディレクトリを"
    STDERR.puts "      カレントディレクトリにして、やりなおしてください"
    exit 1
  end

  T_STANDARD = 0  # Wordbank 以外を出力
  T_WORDBANK = 1  # Wordbank のみ出力

  # コマンドライン引数の処理
  def ARGV.option
    return nil if self.empty?
    arg = self.shift
    if arg =~ /^-/
      return arg
    else
      self.unshift arg
      return nil
    end
  end

  begin
    runType = T_STANDARD
    while option = ARGV.option
      case option
      when '-standard'; runType = T_STANDARD
      when '-wordbank'; runType = T_WORDBANK
      else
        raise '無効なオプションです: ' + option
      end
    end
    raise '辞書ディレクトリを指定してください' if ARGV.size < 1
  rescue => e
    STDERR.puts e.message
    showHelp()
    exit 1
  end

### 大域定数

F_Dic       = 0  # Dictionary
F_Thesaurus = 1  # Thesaurus
F_Usage     = 2  # Usage
F_Grammar   = 3  # Grammar
F_Wordbank  = 4  # Wordbank
F_Image     = 5  # 画像

Files = [
  {
    'title' => 'Collins COBUILD English Dictionary',  # タイトル
    'name0' => 'en-cc3.trd',      # version 1 のファイル名
    'name1' => 'hcp_en-cc3.trd',  # version 2 のファイル名
    'name2' => 'hcp_en-cc3.trd',  # version 3 のファイル名
    'id'    => 'c',               # 項目 ID 接頭辞
    'dir'   => 'DIC',             # EPWING ディレクトリ
  },
  {
    'title' => 'Collins Thesaurus',
    'name0' => 'en-cth.trd',
    'name1' => 'hcp_en-gth.trd',
    'name2' => '',
    'id'    => 't',
    'dir'   => 'THESAURU',
  },
  {
    'title' => 'Collins COBUILD English Usage',
    'name0' => 'en-cus.trd',
    'name1' => 'hcp_en-usg.trd',
    'name2' => '',
    'id'    => 'u',
    'dir'   => 'USAGE',
  },
  {
    'title' => 'Collins COBUILD English Grammar',
    'name0' => 'en-cgr.trd',
    'name1' => 'hcp_en-grm.trd',
    'name2' => '',
    'id'    => 'g',
    'dir'   => 'GRAMMAR',
  },
  {
    'title' => 'Wordbank',
    'name0' => 'en-cwb.trd',
    'name1' => 'hcp_en-wbk.trd',
    'name2' => 'hcp_en-wbk.trd',
    'id'    => 'w',
    'dir'   => 'WBANK',
  },
  {
    'title' => '画像ファイル',
    'name0' => 'en.mbx',
    'name1' => 'hcp_en-cc3.mbx',
    'name2' => 'hcp_en-cc3.mbx',
    'id'    => '',
    'dir'   => '',
  }
]

OutExt = '.html'
CopyrightExt = '(C).html'

ImageDir = 'img'
ImageFileSpec = ImageDir + '/%03d.jpg'
ImageFileOutSpec = ImageDir + '/%03d.gif'

EBSFnames = [ 'Cobuild.ebs', 'Wordbank.ebs' ]
DivEBSFname = 'Wordbank_div.ebs'
GaiziFname    = 'CobuildGaiji.xml'
GaiziMapFname = 'CobuildGaijiMap.xml'

FreqChar = '*'            # 頻度

PrefixExample = '　・ '   # 例文
PrefixSynonym = ' = '     # 同義語
PrefixAntonym = ' ⇔ '    # 反義語

###
def changeExt(fname, newExt)
  fname.sub(/\.[^.]+$/, newExt)
end

def changeDirAndExt(fname, newDir, newExt)
  newDir + '/' + changeExt(File::basename(fname), newExt)
end

def copyFile(inPath, outPath)
  return if File::expand_path(inPath) == File::expand_path(outPath)

  inf = open(inPath, 'rb')
  outf = open(outPath, 'wb')
  outf.write(inf.read())

rescue => e
  STDERR.puts e.message
ensure
  inf.close if inf != nil
  outf.close if outf != nil
end

###
class EBSFile < File

  def printEBS(outDir, version)

    outDir = File::expand_path(outDir).gsub(/\//, '\\')

    puts <<"--------"
InPath=#{outDir}\\
OutPath=#{outDir}\\
IndexFile=
Copyright=
GaijiFile=$(BASE)\\CobuildGaiji.xml
GaijiMapFile=$(BASE)\\CobuildGaijiMap.xml
EBType=0
WordSearchHyoki=1
WordSearchKana=1
EndWordSearchHyoki=1
EndWordSearchKana=1
KeywordSearch=1
ComplexSearch=0
topMenu=0
singleLine=0
kanaSep1=【
kanaSep2=】
makeFig=1
paraHdr=0
ruby=1
paraBr=0
subTitle=0
dfnStyle=0
srchUnit=0
linkChar=0
arrowCode=222A
eijiPronon=1
eijiPartOfSpeech=1
eijiBreak=1
leftMargin=1
indent=0
tableWidth=480
StopWord=a the
delBlank=1
delSym=1
delChars=
refAuto=0
titleWord=1
autoWord=0
HTagIndex=0
DTTagIndex=1
dispKeyInSelList=0
titleOrder=0
channel=0
nBit=0
sampLate=2
optMono=0
Size=10000;50000;4000;32000000;6000;250000;50000;500;500;10000;2000
--------

    [ F_Dic, F_Thesaurus, F_Usage, F_Grammar].each do |v|
      if Files[v]['name' + version] != ''
        outFname = changeExt(Files[v]['name' + version], OutExt)
        copyrightFname = changeExt(Files[v]['name' + version], CopyrightExt)
        title = Files[v]['title']
        dir = Files[v]['dir']
      puts <<"--------"
Book=#{title};#{dir};英和辞典;$(BASE)\\#{copyrightFname};_;GAI16H00;GAI16F00;_;_;_;_;_;_;
Source=$(BASE)\\#{outFname};_;_;HTML;
--------
      end
    end

  end

end

class WordbankEBSFile < EBSFile

  def printEBS(outDir, version, divEBS)

    outDir = File::expand_path(outDir).gsub(/\//, '\\')
    copyrightFname = changeExt(Files[F_Wordbank]['name' + version], CopyrightExt)

    puts <<"--------"
InPath=#{outDir}\\
OutPath=#{outDir}-WB\\
IndexFile=
Copyright=$(BASE)\\#{copyrightFname}
GaijiFile=$(BASE)\\CobuildGaiji.xml
GaijiMapFile=$(BASE)\\CobuildGaijiMap.xml
EBType=0
WordSearchHyoki=0
WordSearchKana=0
EndWordSearchHyoki=0
EndWordSearchKana=0
KeywordSearch=1
ComplexSearch=0
topMenu=0
singleLine=1
kanaSep1=【
kanaSep2=】
makeFig=1
paraHdr=0
ruby=1
paraBr=0
subTitle=0
dfnStyle=0
srchUnit=0
linkChar=0
arrowCode=222A
eijiPronon=1
eijiPartOfSpeech=1
eijiBreak=1
leftMargin=1
indent=0
tableWidth=480
StopWord=a the
delBlank=1
delSym=1
delChars=
refAuto=0
titleWord=0
autoWord=0
autoEWord=1
HTagIndex=0
DTTagIndex=1
dispKeyInSelList=0
titleOrder=0
channel=0
nBit=0
sampLate=2
optMono=0
--------

    [ F_Wordbank ].each do |v|
      if divEBS
        puts <<"--------"
Size=10000;10000;4000;35000000;60000;2350000;50000;500;500;10000;2000
--------
        (1..2).each do |n|
          num = n.to_s
          outFname = changeExt(Files[v]['name' + version], num + OutExt)
          title = Files[v]['title'] + ' ' + num
          dir = Files[v]['dir'] + num
          puts <<"--------"
Book=#{title};#{dir};英和辞典;_;_;GAI16H00;GAI16F00;_;_;_;_;_;_;
Source=$(BASE)\\#{outFname};_;_;HTML;
--------
        end
      else
        title = Files[v]['title']
        dir = Files[v]['dir']
        puts <<"--------"
Size=10000;10000;4000;49000000;60000;2350000;50000;500;500;10000;2000
Book=#{title};#{dir};英和辞典;_;_;GAI16H00;GAI16F00;_;_;_;_;_;_;
--------
        (1..2).each do |n|
          num = n.to_s
          outFname = changeExt(Files[v]['name' + version], num + OutExt)
          puts <<"--------"
Source=$(BASE)\\#{outFname};_;_;HTML;
--------
        end
      end
    end

  end

end

### タグ変換

T = Hash::new(0)

def tagstart(a, head, tail)
  if a.empty?
    r = head; a.push(tail)
  else
    r = a.last + head; a.push(tail)
  end
  r
end

def tagend(a)
  if a.empty?
    r = '&gt;'
  else
    r = a.pop
    unless a.empty?
      r += a.last.sub(/\//, '')
    end
  end
  r
end

def convert(str)
  a = []; r = ''; p = 0
  while n = str.index(/<|>/, p)
    r += str[p...n]

    if str[n, 1] == '<'
      if str[n + 2, 1] == '.'    # <tag.str>
        wyc=str[n+1,1]
        case wyc
        when 'e', 'f', 'x', 'u', 'b', 'w'
          r += tagstart(a, '<b_'+wyc+'>', '</b_'+wyc+'>')
        when 'g', 'o', 'i', 'v'
          r += tagstart(a, '<i_'+wyc+'>', '</i_'+wyc+'>')
        when 'c'
          r += tagstart(a, '<i_'+wyc+'>(', ')</i_'+wyc+'>')
        when 'A', 'B'
          r += tagstart(a, '<b_'+wyc+'>', '</b_'+wyc+'>')
        when 'O'
          r += tagstart(a, '<i_'+wyc+'>', '</i_'+wyc+'>')
        when 'E'
          r += tagstart(a, '<sup_'+wyc+'>', '</sup_'+wyc+'>')
        when 'S'     # Symbol
          r += tagstart(a, '<sym)'+wyc+'>', '</sym_'+wyc+'>')
        else  # error
          T['<' + str[n + 1, 2] + '>'] += 1
          r += tagstart(a, '&lt;' + str[n + 1, 2], '&gt;')
        end
        p = n + 3
      else                       # <tag>
        p = n + 1
        until str[p, 1] == '>'
          p += 1
        end
        s = str[(n + 1)...p]
        if s =~/^[zAB]/         # 発音アイコン
          r += ' '      # ???
        elsif s == 'DW'                  # Warning
          r += tagstart(a, '<b_DW>', '</b_DW>') + '[!]' + tagend(a)
        elsif s == 'li'
          r += ', '
        elsif s == 'lb'
	  r +='<lb></lb>'
        elsif s == 'le'
          r += '<le></le>' # ignore
        elsif s == 'h'           # 分綴
          r += '&middot;'
        elsif s == 'inferior'    # errata?
          r += tagstart(a, '<sub>', '</sub>')
        elsif s == '/inferior'   # errata?
          r += tagend(a)
        else  # error
          T['<' + s + '>'] += 1
          r += '&lt;' + s + '&gt;'
        end
        p += 1
      end
    else
      r += tagend(a)
      p = n + 1
    end
  end
  r += str[p, str.size]

  r = r.gsub(/<\/([ib])><\1>/, '')
  r = r.gsub(/<sym>(.+?)<\/sym>/) {
    code = $1
    case code
    when 'mu_flat'   then s = '♭'        # フラット記号
    when 'mu_sharp'  then s = '♯'        # シャープ記号
    when 'sy_check'  then s = '&#x2713;'  # tick
    when 'ipa_schwa' then s = '&#x0259;'  # schwa
    else
      T['<sym>' + code + '</sym>'] += 1
      s = code
    end
    s
  }

  r.gsub(/(&)(.+?;)(.)/) {
    case $2
    when 'grave;', 'acute;', 'circ;', 'tilde;', 'uml;', 'cedil;'
      $1 + $3 + $2
    else
      $&
    end
  }

end

def printUnknownTags
  unless T.empty?
    puts ''
    puts '==== Unknown Tags ===='
    T.sort.each { |tag, n|
      printf("%s  %4d\n", tag, n)
    }
  end
end

def checkFlag(tag, flag, mask)
  b = flag & ~mask
  if b != 0
    s = '%s: %02X %02X' % [tag, flag, b]
    puts ''
    puts 'Unknown flag: ' + s
#    f.puts '{' + s + '}'
  end
end

### 見出部出力
def printHead(d, type, f, idchar, idnum)

  ch = d.getFlag('rec')
  hasHead  = (ch & 0x01 != 0)  # 見出し部
  hasData  = (ch & 0x02 != 0)  # 追加データ
  hasSound = (ch & 0x80 != 0)  # 音声データ
  checkFlag('rec', ch, 0x83) # if $DEBUG

  hasEntry = hasVariant = hasParts = hasForms = hasUsage = hasHeadSound = false
  if hasHead
    ch = d.getFlag('head')
    hasEntry     = (ch & 0x01 != 0)   # 見出し語
    hasVariant   = (ch & 0x02 != 0)   # 異形/キー? (類語、文法のみ)
    hasParts     = (ch & 0x08 != 0)   # 品詞 (類語のみ)
    hasForms     = (ch & 0x10 != 0)   # 変化形 CD-ROM v3.0
    hasUsage     = (ch & 0x20 != 0)   # 用法 (類語のみ)
    hasHeadSound = (ch & 0x80 != 0)   # 発音
    checkFlag('head', ch, 0xBB) # if $DEBUG

    entry   = d.decode() if hasEntry
    variant = d.decode() if hasVariant
    parts   = d.decode() if hasParts
    forms   = d.decode() if hasForms
    usage   = d.decode() if hasUsage
    d.decode() if hasHeadSound  # 読み飛ばす
  end

  hasReason = hasSyntax = hasHyphen = hasComment = hasSeq = hasFreq = false
  if hasData
    ch = d.getFlag('data')
    hasReason  = (ch & 0x01 != 0)  # 別見出しにした理由
    hasSyntax  = (ch & 0x02 != 0)  # 構文 Resource Pack
    hasHyphen  = (ch & 0x04 != 0)  # 分綴 CD-ROM v3.0
    hasComment = (ch & 0x08 != 0)  # 注釈
    hasSeq     = (ch & 0x10 != 0)  # 章節番号 (文法のみ)
    hasFreq    = (ch & 0x20 != 0)  # 頻度
    checkFlag('data', ch, 0x3F) # if $DEBUG

    reason  = d.decode() if hasReason
    syntax  = d.decode() if hasSyntax
    hyphen  = d.decode() if hasHyphen
    comment = d.decode() if hasComment
    seq     = d.decode() if hasSeq
    if hasFreq
      freq = '<freq>'
      s = d.readStr(1)
      s[0].times {
        freq += FreqChar
      }
      freq+='</freq>'
    end

  end

  if hasSound
    while d.getc != 0x00
      s = d.readStr(3)    # 読み飛ばす
    end
  end

  ###########

  if idnum < 1
    f.puts '<dt>Copyright</dt>'
    f.puts '<dd>'
    return
  end

  if (type == F_Wordbank)
    $head = entry
    return
  end

  head = ''
  head += seq + ' ' if hasSeq
  head += entry     if hasEntry
  tail = ''
  tail += ' ' + variant      if hasVariant && ( type == F_Thesaurus )
  tail += ' ' + freq         if hasFreq
  tail += ' (' + usage + ')' if hasUsage

  s = convert('<e.' + head + '>' + tail)

  id = idchar + sprintf("%05d", idnum)
  f.puts '<dt id="' + id + '">' + s.strip + '</dt>'

  entry = convert(entry.sub(/ \d+$/, ''))  # 見出し語区分の数字を削除
  f.puts '<key type="表記">' + entry + '</key>'
  a = entry.split(/ +/)
  a.each { |x|
    f.puts '<key type="クロス">' + x + '</key>'
  }
  f.puts '<key type="表記">' + seq + '</key>' if hasSeq

  f.puts '<dd>'

  data = ''
  data += hyphen + ' '                     if hasHyphen
  data += ' ' + forms.sub(/#{entry}/, '') + ' ' if hasForms
  if hasParts
    if hasSyntax
      data += '[' + parts + ': ' + syntax + '] '
    else
      data += '[' + parts + '] '
    end
  end
  data += reason + ' ; '                   if hasReason
  data += comment                          if hasComment

  if data != ''
    f.puts '<data>' + convert(data).sub(/ ;? *$/, '') + '</data>'
  end

end

### 本体出力
def printItem(d, type, f)
  f.puts '<item>'

  ch = d.getFlag('item')
  hasHead   = (ch & 0x01 != 0)   # 小見出し
  hasRemark = (ch & 0x02 != 0)   # 用法など
  hasBody   = (ch & 0x10 != 0)   # 本文
  hasRel    = (ch & 0x40 != 0)   # 関連語
  hasImage  = (ch & 0x80 != 0)   # 画像
  checkFlag('item', ch, 0xD3) # if $DEBUG

  hasTitle = hasSubx = hasParts = hasDeriv = hasNote = false
  if hasHead
    ch = d.getFlag('itemhead')
    hasTitle = (ch & 0x01 != 0)  # 見出し
    hasSubx  = (ch & 0x02 != 0)  # ?? errata CD-ROM v3.0  (faff の 1 件のみ)
    hasParts = (ch & 0x08 != 0)  # 品詞
    hasDeriv = (ch & 0x10 != 0)  # 派生形/変化形
    hasNote  = (ch & 0x20 != 0)  # 説明  Resource Pack
    checkFlag('itemhead', ch, 0x3B) # if $DEBUG

    title = d.decode() if hasTitle
    subx  = d.decode() if hasSubx
    parts = d.decode() if hasParts
    deriv = d.decode() if hasDeriv
    note  = d.decode() if hasNote
  end

  hasVariant = hasHyphen = hasComment = hasStyle = hasBullet = hasNum = false
  if hasRemark
    ch = d.getFlag('remark')
    hasVariant = (ch & 0x02 != 0)  # 異形
    hasHyphen  = (ch & 0x04 != 0)  # 分綴 CD-ROM v3.0
    hasComment = (ch & 0x08 != 0)  # 注釈 (類語のみ、表示されない)
    hasStyle   = (ch & 0x10 != 0)  # 用法 (文法では章節番号)
    hasBullet  = (ch & 0x20 != 0)  # ?? (辞書本体のみ)
    hasNum     = (ch & 0x80 != 0)  # 番号または記号
    checkFlag('remark', ch, 0xBE) # if $DEBUG

    variant = d.decode() if hasVariant
    hyphen  = d.decode() if hasHyphen
    comment = d.decode() if hasComment
    style   = d.decode() if hasStyle
    if hasBullet
      ch = d.getFlag('bullet')     # ???
    end
    num = d.decode() if hasNum
  end

  hasMeaning = hasExample = hasTable = hasXRef = hasSeeAlso = false
  if hasBody
    ch = d.getFlag('body')
    hasMeaning = (ch & 0x01 != 0)   # 意味
    hasExample = (ch & 0x02 != 0)   # 例文
    hasTable   = (ch & 0x04 != 0)   # 表
    hasXRef    = (ch & 0x08 != 0)   # 参照
    hasSeeAlso = (ch & 0x40 != 0)   # 参照 CD-ROM v3.0
    checkFlag('body', ch, 0x4F) # if $DEBUG

    if hasMeaning
      meaning = d.decode()
    end
    if hasExample
      n = d.getc
      example = []
      n.times {
        example.push(d.decode())
      }
    end
    #### 実際に表示するときは例の前に表示する???
    if hasTable
      n = d.getc
      table = []
      n.times {
        table.push(d.decode())
      }
    end
    if hasXRef  # 参照
      n = d.getc
      xref = []
      n.times {
        xref.push(d.decode())
      }
    end
    seealso = d.decode() if hasSeeAlso
  end

  hasSynonym = hasAntonym = false
  if hasRel
    ch = d.getFlag('rel')
    hasSynonym = (ch & 0x01 != 0)  # 同義語
    hasAntonym = (ch & 0x02 != 0)  # 反義語
    checkFlag('rel', ch, 0x03) # if $DEBUG

    synonym = d.decode() if hasSynonym
    antonym = d.decode() if hasAntonym
  end

  if hasImage
    ch = d.getFlag('image')
    imageNo, = d.readStr(4).unpack('V*')
  end

  ###########

  if type == F_Wordbank && hasExample
    example.each do |v|
      s = convert(v)
      head = $head.sub(/^\*/, '')  # '*' をとる
      title = head.sub(/written/, 'W').sub(/spoken/, 'S') + ' '
      a = s.split(/ +/, 10)
      a.each do |x|
        if title.length > 25
          title += '...'
          break
        end
        title += ' ' + x
      end
      title.gsub!(/"/, '&quot;')
      title.gsub!(/<.+?>/, '')    # EBStudio Bug??
      f.puts '<dt title="' + title + '">' + head + '</dt>'
      f.puts '<dd>' + s + '</dd>' unless v.empty?
    end
    return
  end

  if type == F_Grammar
    s = ''
    s += ' <e.' + style + '>' if hasStyle  # 章節番号
    s += ' <e.' + title + '>' if hasTitle
    if s != ''
      f.puts '<pyy>' + convert(s).strip + '</pyy>'
      f.puts '<key type="表記">' + style + '</key>' if hasStyle
    end
    num = ''
  else
    s = ''
#    s += ' <e.' + title + '>' if hasTitle
#    s += ' <e.' + deriv + '>' if hasDeriv
    if hasDeriv
      if hasTitle   # CD-ROM v2.0
        if hasNum && num == '@'   # 派生形
          s += ' <e.##dfn##' + title + '##/dfn##> ' + deriv
          num = '&xSym1;'
        else
          s += ' <e.' + title + '> ' + deriv  # ???
        end
        if hasSubx   # CD-ROM v3.0  1 件のみ
          s += ' ' + subx
        end
      else          # CD-ROM v1.0
        if hasNum && num == '@'   # 派生形
          derivs = deriv.split()
          s += ' <e.##dfn##' + derivs.shift + '##/dfn##>'
          derivs.each do |x|
            s += ' ' + x
          end
          num = '&xSym1;'
        else
          s += ' <e.' + deriv + '>'
        end
      end
    else
      s += ' <e.' + title + '>' if hasTitle
    end
    s += ' ' + variant        if hasVariant
    s += ' ' + hyphen         if hasHyphen
    s += ' [' + parts + ']'   if hasParts
    s += ' ' + style          if hasStyle
    s += ' ' + comment        if hasComment

    if hasNum
      if type == F_Thesaurus && num == '=='
        num = ''
      else
        num = '&xSym2;' if num == '+'
        num = '<b_aa>' + num + '</b_aa> '
      end
    else
      num =  ''
    end

    if s != ''
      s = convert(s).gsub(/##(\/?dfn)##/) { '<' + $1 + '>' }
      f.puts '<pxx>' + num + s.strip + '</pxx>'
      num = ''
    end
  end

#  if hasNum && num == '@' && hasDeriv
#    f.puts '<key type="表記">' + convert(deriv).strip + '</key>'
#  end

  if hasNote
    f.puts '<note>' + convert(note) + '</note>'
  end

  if hasMeaning
    f.puts '<meaning>' + num + convert(meaning) + '</meaning>'
    num = ''
  end

  if hasTable
    f.puts '<table>' + num + '</table>' if num != ''
    table.each { |v|
                                # 最初の <li> を削除
      f.puts '<table_sub>' + convert('<e.' + v.sub(/<li>/, '') + '>') + '</table_sub>'
    }
  end

  if hasExample
    f.puts '<example>' + num + '</example>' if num != ''
    num = ''
    example.each { |v|
      f.puts '<example_sub>' + PrefixExample + convert(v) + '</example_sub>' unless v.empty?
    }
  end

  if hasXRef
    f.puts '<ref>' + num + '</ref>' if num != ''
    num = ''
    xref.each { |v|
      f.puts '<ref_sub>' + convert(v) + '</ref_sub>'
    }
  end

  # CD-ROM v3.0
  if hasSeeAlso
    f.puts '<see_also>' + convert(seealso) + '</see_also>'
  end

  if hasImage
#    f.puts '<p>...[IMAGE]...</p>'
    f.puts '<p>' + num + '<img src="' + sprintf(ImageFileSpec, imageNo) + '"></p>'
    num = ''
  end

  if hasRel
    s = ''
    s += PrefixSynonym + convert('<e.' + synonym + '>') if hasSynonym
    s += PrefixAntonym + convert('<e.' + antonym + '>') if hasAntonym
    f.puts '<rel>' + num + s.strip + '</rel>'
    num = ''
  end

  ## この場所でいいか
  if hasSynonym
    a = convert(synonym).split(',')
    a.each { |v|
      f.puts '<key type="条件">' + v.strip + '</key>'
    }
  end

  if hasAntonym
    a = convert(antonym).split(',')
    a.each { |v|
      f.puts '<key type="条件">' + v.strip + '</key>'
    }
  end

  # 段落区切り
  if type == F_Usage || type == F_Grammar
    f.puts '<par></par>'
  end
  f.puts '</item>'

end

###
class OutHTML < File

  def writeHeader(title = 'Cobuild')
    puts '<html>'
    puts '<head>'
    puts '<title>' + title + '</title>'
    puts '</head>'
    puts '<body>'
    puts '<dl>'
  end

  def writeFooter()
    puts '</dl>'
    puts '</body>'
    puts '</html>'
  end

end

### 先頭レコードを著作権ファイルに出力
def printCopyright(fname, type, f, d)

  OutHTML::open(fname, 'w') do |cf|
    cf.writeHeader(Files[type]['title'])
    num = 0
    rec = f.getRec(num)
    d.setData(rec)
    items = d.getc               # 本文項目数
    printHead(d, type, cf, Files[type]['id'], num)
    items.times do
      printItem(d, type, cf)
    end
    cf.puts '</dd>'
    cf.writeFooter
  end

end

###
def printBody(f, type, outf, d, from, to, max)
  for num in from..to do
    rec = f.getRec(num)

#puts rec.unpack('H*')[0].upcase.scan(/../).join(' ')

    STDERR.print num, '/', max, "\r" if num % 10 == 0
#    outf.printf("(%5d)", num)

    d.setData(rec)
    items = d.getc               # 本文項目数
    printHead(d, type, outf, Files[type]['id'], num)
    items.times do |n|
#      outf.printf("==%d", n)
      printItem(d, type, outf)
    end
    outf.puts '</dd>' if type != F_Wordbank
  end
end

###
def printFile(fname, type, outDir)

if $DEBUG
  d = CobuildDecoderDebug::new
else
  d = CobuildDecoder::new
end

  STDERR.print Files[type]['title'], ' を出力しています...', "\n"

  CobuildFile.open(fname, 'rb') do |f|
    f.init
    f.makeIndex

    # 著作権ファイル出力
    copyrightFname = changeDirAndExt(fname, outDir, CopyrightExt)
    printCopyright(copyrightFname, type, f, d)

    # 本体出力
    max = count = f.recCount - 1
#count = 350

    STDERR.print 0, '/', max, "\r"

    if type == F_Wordbank  # 2 つのファイルに分割して出力
      outFname = changeDirAndExt(fname, outDir, '1' + OutExt)
      outf = OutHTML::open(outFname, 'w')
      outf.writeHeader(Files[type]['title'])
      printBody(f, type, outf, d, 1, count / 2, max)
      outf.writeFooter
      outf.close

      outFname = changeDirAndExt(fname, outDir, '2' + OutExt)
      outf = OutHTML::open(outFname, 'w')
      outf.writeHeader(Files[type]['title'])
      printBody(f, type, outf, d, count / 2 + 1, count, max)
      outf.writeFooter
      outf.close
    else
      outFname = changeDirAndExt(fname, outDir, OutExt)
      outf = OutHTML::open(outFname, 'w')
      outf.writeHeader(Files[type]['title'])
      printBody(f, type, outf, d, 1, count, max)
      outf.writeFooter
      outf.close
    end

    STDERR.print count, '/', max, "\n"

if $DEBUG
  d.printFlags
  d.printUnknown
end

  printUnknownTags
  T.clear

  end

end

###
def writeImage(fname, outDir)

  STDERR.print Files[F_Image]['title'], ' を出力しています...', "\n"
  if fname != ''
    imgDir = outDir + '/' + ImageDir
    Dir.mkdir(imgDir) unless File::exist?(imgDir)
    CobuildImageFile.open(fname, 'rb') do |f|
      f.init
      f.each_with_index do |img, n|
        if img.size != 0
          open(outDir + '/' + sprintf(ImageFileOutSpec, n), 'wb') do |outf|
            outf.write(img)
          end
        end
      end
    end
  end
  STDERR.print "注意: EBStudio で変換を実行する前に\n#{imgDir} にある .gif ファイルを .jpg ファイルに変換してください\n"

end

### --------------------------------------------------------------------
def main(runType, scrPath)

  inDir = ARGV.shift
  inDir = inDir.gsub(/\\/, '/').sub(/\/$/, '')
  outDir = ARGV.shift || '.'
  outDir = outDir.gsub(/\\/, '/').sub(/\/$/, '')

  # バージョン判定
  version = ''
  [ F_Dic, F_Thesaurus, F_Usage, F_Grammar, F_Wordbank, F_Image ].each do |v|
    if File::exist?(inDir + '/' + Files[v]['name0'])
      version = '0'
      break
    elsif File::exist?(inDir + '/' + Files[v]['name1'])
      version = '1'
      break
    end
  end
  if version == ''
    STDERR.print "#{inDir} に必要なファイルが見つかりません\n"
    exit 3
  end
  # シソーラスがなければ CD-ROM v3 とみなす
  if version == '1'
    if not File::exist?(inDir + '/' + Files[F_Thesaurus]['name1'])
      version = '2'
    end
  end

  start = Time::now
  STDERR.print "開始日時: ", start.strftime('%Y-%m-%d %X'), "\n"

  if runType == T_STANDARD

    # 辞書出力
    [ F_Dic, F_Thesaurus, F_Usage, F_Grammar].each do |v|
      if Files[v]['name' + version] != ''
        fname = inDir + '/' + Files[v]['name' + version]
        if File::exist?(fname)
          printFile(fname, v, outDir)
        else
          STDERR.print "#{fname}が見つかりません\n"
        end
      end
    end

    # 画像出力
    [ F_Image ].each do |v|
      fname = inDir + '/' + Files[v]['name' + version]
      if File::exist?(fname)
        writeImage(fname, outDir)
      else
        STDERR.print "#{fname}が見つかりません\n"
      end
    end

    # 作業環境定義ファイル出力
    EBSFile::open(outDir + '/' + EBSFnames[T_STANDARD], 'w') do |f|
      f.printEBS(outDir, version)
    end

  else

    # 辞書出力
    [ F_Wordbank ].each do |v|
      fname = inDir + '/' + Files[v]['name' + version]
      if File::exist?(fname)
        printFile(fname, v, outDir)
      else
        STDERR.print "#{fname}が見つかりません\n"
      end
    end

    # 作業環境定義ファイル出力
    WordbankEBSFile::open(outDir + '/' + EBSFnames[T_WORDBANK], 'w') do |f|
      f.printEBS(outDir, version, false)
    end
    WordbankEBSFile::open(outDir + '/' + DivEBSFname, 'w') do |f|
      f.printEBS(outDir, version, true)
    end

  end

  # 外字ファイルのコピー
  copyFile(scrPath + '/' + GaiziFname, outDir + '/' + GaiziFname)
  copyFile(scrPath + '/' + GaiziMapFname, outDir + '/' + GaiziMapFname)

  finish = Time::now
  STDERR.print "終了日時: ", finish.strftime('%Y-%m-%d %X'), "\n"
  STDERR.print "処理時間: ", Time::at(finish.to_i - start.to_i).utc.strftime('%X'), "\n"

end

### --------------------------------------------------------------------
main(runType, scrPath)
