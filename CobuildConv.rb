#!/user/local/bin/ruby -Ks
def showHelp; scrName = File::basename($0.gsub(/\\/, '/'));
puts <<"================================================"
�T�v: COBUILD �� EBStudio �p���̓t�@�C�����쐬����
�\��: ruby -Ks #{scrName} [<options>] <inDir> [<outDir>]
  <options>
    -standard  Wordbank �ȊO��ϊ����� (����l)
    -wordbank  Wordbank �݂̂�ϊ�����
  <inDir>   .trd �t�@�C���̂���f�B���N�g��
  <outDir>  �o�̓f�B���N�g�� (�w��Ȃ��Ȃ�J�����g�f�B���N�g��)
��:
* COBUILD CD-ROM v1.0 (X:) ����쐬����
  ruby -Ks #{scrName} X:\\ D:\\EPWING\\Cobuild
* COBUILD CD-ROM v2.0/3.0 (X:) ���� Wordbank ���쐬����
  ruby -Ks #{scrName} -wordbank X:\\DATA D:\\EPWING\\Cobuild
================================================
end
=begin
�o��: *.html  EBStudio ���̓t�@�C��
      *.ebs   EBStudio ��Ɗ���`�t�@�C��
����:
  v1.00 2003-06-28 by nomad
    ���J
  v1.10 2003-07-15 by nomad
    Wordbank �ɑΉ� (-wordbank �I�v�V����)
    CD-ROM v2.0 �Ŕh���`�̍������쐬����Ȃ��o�O���C��
    CD-ROM v1.0 �Ŕh���`�̌����v�������������쐬����Ȃ��o�O���C��
    ���쌠�t�@�C����ǉ�
    �O���t�@�C�����o�͐�ɃR�s�[
    ���̑�
  v1.11 2003-07-29 by nomad
    CD-ROM v2.0 �̃t�@�C�����̃~�X���C�� (hcp_en_cc3.trd -> hcp_en-cc3.trd �Ȃ�)
  v1.12 2003-07-30 by nomad
    �t�@�C�����̏C������ (hcp_en_cc3.mbx -> hcp_en-cc3.mbx)
  v1.20 2004-01-18 by nomad
    CD-ROM v3.0 �ɑΉ�
    InPath ���΃p�X�ŏo�͂���悤�ɏC��
  v1.30 2004-02-04 by nomad
    Resource Pack �ɑΉ�
    Wordbank �� 1 ���Ђɂ��� ebs ��W���ɂ��A2 ���Ђɂ��� ebs ���o��
    Wordbank �ȊO�̊O���Ɋ��S�Ή�
  v1.31 2004-02-17 by nomad
    Mac ���Ŏ��s�ł���悤�C��
  v1.32 2004-02-26 by nomad
    &Frac13; ���O���ɕϊ�����Ȃ������̂��C��
    �����ɕ����Q�� (&...;) ������ƊO���ɕϊ�����Ȃ��ꍇ���������̂��C��
    Resource Pack �̋L���Aipa_schwa �ɑΉ�
    tick mark �̊O����ǉ�
����: Copyright (C) 2003-2004, nomad
      �I�[�v���\�[�X����
=end

  # ���C�u�����̃��[�h
  scrPath = File::dirname($0.gsub(/\\/, '/'))
  scrName = File::basename($0.gsub(/\\/, '/'))
  $LOAD_PATH.unshift(scrPath)     # �X�N���v�g�p�X�����[�h�p�X�ɒǉ�

  begin
    libName = 'CobuildLib.rb'
    require libName
  rescue LoadError => e
    STDERR.puts e.message
    STDERR.puts "�Ώ�: #{scrName} �� #{libName} �̂���f�B���N�g����"
    STDERR.puts "      �J�����g�f�B���N�g���ɂ��āA���Ȃ����Ă�������"
    exit 1
  end

  T_STANDARD = 0  # Wordbank �ȊO���o��
  T_WORDBANK = 1  # Wordbank �̂ݏo��

  # �R�}���h���C�������̏���
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
        raise '�����ȃI�v�V�����ł�: ' + option
      end
    end
    raise '�����f�B���N�g�����w�肵�Ă�������' if ARGV.size < 1
  rescue => e
    STDERR.puts e.message
    showHelp()
    exit 1
  end

### ���萔

F_Dic       = 0  # Dictionary
F_Thesaurus = 1  # Thesaurus
F_Usage     = 2  # Usage
F_Grammar   = 3  # Grammar
F_Wordbank  = 4  # Wordbank
F_Image     = 5  # �摜

Files = [
  {
    'title' => 'Collins COBUILD English Dictionary',  # �^�C�g��
    'name0' => 'en-cc3.trd',      # version 1 �̃t�@�C����
    'name1' => 'hcp_en-cc3.trd',  # version 2 �̃t�@�C����
    'name2' => 'hcp_en-cc3.trd',  # version 3 �̃t�@�C����
    'id'    => 'c',               # ���� ID �ړ���
    'dir'   => 'DIC',             # EPWING �f�B���N�g��
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
    'title' => '�摜�t�@�C��',
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

FreqChar = '*'            # �p�x

PrefixExample = '�@�E '   # �ᕶ
PrefixSynonym = ' = '     # ���`��
PrefixAntonym = ' �� '    # ���`��

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
kanaSep1=�y
kanaSep2=�z
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
Book=#{title};#{dir};�p�a���T;$(BASE)\\#{copyrightFname};_;GAI16H00;GAI16F00;_;_;_;_;_;_;
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
kanaSep1=�y
kanaSep2=�z
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
Book=#{title};#{dir};�p�a���T;_;_;GAI16H00;GAI16F00;_;_;_;_;_;_;
Source=$(BASE)\\#{outFname};_;_;HTML;
--------
        end
      else
        title = Files[v]['title']
        dir = Files[v]['dir']
        puts <<"--------"
Size=10000;10000;4000;49000000;60000;2350000;50000;500;500;10000;2000
Book=#{title};#{dir};�p�a���T;_;_;GAI16H00;GAI16F00;_;_;_;_;_;_;
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

### �^�O�ϊ�

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
        case str[n + 1, 1]
        when 'e', 'f', 'x', 'u', 'b', 'w'
          r += tagstart(a, '<b>', '</b>')
        when 'g', 'o', 'i', 'v'
          r += tagstart(a, '<i>', '</i>')
        when 'c'
          r += tagstart(a, '<i>(', ')</i>')
        when 'A', 'B'
          r += tagstart(a, '<b>', '</b>')
        when 'O'
          r += tagstart(a, '<i>', '</i>')
        when 'E'
          r += tagstart(a, '<sup>', '</sup>')
        when 'S'     # Symbol
          r += tagstart(a, '<sym>', '</sym>')
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
        if s =~ /^[zAB]/         # �����A�C�R��
          r += ' '      # ???
        elsif s == 'DW'                  # Warning
          r += tagstart(a, '<b>', '</b>') + '[!]' + tagend(a)
        elsif s == 'li'
          r += ', '
        elsif s == 'lb' || s == 'le'
          r += '' # ignore
        elsif s == 'h'           # ����
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
    when 'mu_flat'   then s = '��'        # �t���b�g�L��
    when 'mu_sharp'  then s = '��'        # �V���[�v�L��
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

### ���o���o��
def printHead(d, type, f, idchar, idnum)

  ch = d.getFlag('rec')
  hasHead  = (ch & 0x01 != 0)  # ���o����
  hasData  = (ch & 0x02 != 0)  # �ǉ��f�[�^
  hasSound = (ch & 0x80 != 0)  # �����f�[�^
  checkFlag('rec', ch, 0x83) # if $DEBUG

  hasEntry = hasVariant = hasParts = hasForms = hasUsage = hasHeadSound = false
  if hasHead
    ch = d.getFlag('head')
    hasEntry     = (ch & 0x01 != 0)   # ���o����
    hasVariant   = (ch & 0x02 != 0)   # �ٌ`/�L�[? (�ތ�A���@�̂�)
    hasParts     = (ch & 0x08 != 0)   # �i�� (�ތ�̂�)
    hasForms     = (ch & 0x10 != 0)   # �ω��` CD-ROM v3.0
    hasUsage     = (ch & 0x20 != 0)   # �p�@ (�ތ�̂�)
    hasHeadSound = (ch & 0x80 != 0)   # ����
    checkFlag('head', ch, 0xBB) # if $DEBUG

    entry   = d.decode() if hasEntry
    variant = d.decode() if hasVariant
    parts   = d.decode() if hasParts
    forms   = d.decode() if hasForms
    usage   = d.decode() if hasUsage
    d.decode() if hasHeadSound  # �ǂݔ�΂�
  end

  hasReason = hasSyntax = hasHyphen = hasComment = hasSeq = hasFreq = false
  if hasData
    ch = d.getFlag('data')
    hasReason  = (ch & 0x01 != 0)  # �ʌ��o���ɂ������R
    hasSyntax  = (ch & 0x02 != 0)  # �\�� Resource Pack
    hasHyphen  = (ch & 0x04 != 0)  # ���� CD-ROM v3.0
    hasComment = (ch & 0x08 != 0)  # ����
    hasSeq     = (ch & 0x10 != 0)  # �͐ߔԍ� (���@�̂�)
    hasFreq    = (ch & 0x20 != 0)  # �p�x
    checkFlag('data', ch, 0x3F) # if $DEBUG

    reason  = d.decode() if hasReason
    syntax  = d.decode() if hasSyntax
    hyphen  = d.decode() if hasHyphen
    comment = d.decode() if hasComment
    seq     = d.decode() if hasSeq
    if hasFreq
      freq = ''
      s = d.readStr(1)
      s[0].times {
        freq += FreqChar
      }
    end

  end

  if hasSound
    while d.getc != 0x00
      s = d.readStr(3)    # �ǂݔ�΂�
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

  entry = convert(entry.sub(/ \d+$/, ''))  # ���o����敪�̐������폜
  f.puts '<key type="�\�L">' + entry + '</key>'
  a = entry.split(/ +/)
  a.each { |x|
    f.puts '<key type="�N���X">' + x + '</key>'
  }
  f.puts '<key type="�\�L">' + seq + '</key>' if hasSeq

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
    f.puts '<p>' + convert(data).sub(/ ;? *$/, '') + '</p>'
  end

end

### �{�̏o��
def printItem(d, type, f)

  ch = d.getFlag('item')
  hasHead   = (ch & 0x01 != 0)   # �����o��
  hasRemark = (ch & 0x02 != 0)   # �p�@�Ȃ�
  hasBody   = (ch & 0x10 != 0)   # �{��
  hasRel    = (ch & 0x40 != 0)   # �֘A��
  hasImage  = (ch & 0x80 != 0)   # �摜
  checkFlag('item', ch, 0xD3) # if $DEBUG

  hasTitle = hasSubx = hasParts = hasDeriv = hasNote = false
  if hasHead
    ch = d.getFlag('itemhead')
    hasTitle = (ch & 0x01 != 0)  # ���o��
    hasSubx  = (ch & 0x02 != 0)  # ?? errata CD-ROM v3.0  (faff �� 1 ���̂�)
    hasParts = (ch & 0x08 != 0)  # �i��
    hasDeriv = (ch & 0x10 != 0)  # �h���`/�ω��`
    hasNote  = (ch & 0x20 != 0)  # ����  Resource Pack
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
    hasVariant = (ch & 0x02 != 0)  # �ٌ`
    hasHyphen  = (ch & 0x04 != 0)  # ���� CD-ROM v3.0
    hasComment = (ch & 0x08 != 0)  # ���� (�ތ�̂݁A�\������Ȃ�)
    hasStyle   = (ch & 0x10 != 0)  # �p�@ (���@�ł͏͐ߔԍ�)
    hasBullet  = (ch & 0x20 != 0)  # ?? (�����{�̂̂�)
    hasNum     = (ch & 0x80 != 0)  # �ԍ��܂��͋L��
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
    hasMeaning = (ch & 0x01 != 0)   # �Ӗ�
    hasExample = (ch & 0x02 != 0)   # �ᕶ
    hasTable   = (ch & 0x04 != 0)   # �\
    hasXRef    = (ch & 0x08 != 0)   # �Q��
    hasSeeAlso = (ch & 0x40 != 0)   # �Q�� CD-ROM v3.0
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
    #### ���ۂɕ\������Ƃ��͗�̑O�ɕ\������???
    if hasTable
      n = d.getc
      table = []
      n.times {
        table.push(d.decode())
      }
    end
    if hasXRef  # �Q��
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
    hasSynonym = (ch & 0x01 != 0)  # ���`��
    hasAntonym = (ch & 0x02 != 0)  # ���`��
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
      head = $head.sub(/^\*/, '')  # '*' ���Ƃ�
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
    s += ' <e.' + style + '>' if hasStyle  # �͐ߔԍ�
    s += ' <e.' + title + '>' if hasTitle
    if s != ''
      f.puts '<p>' + convert(s).strip + '</p>'
      f.puts '<key type="�\�L">' + style + '</key>' if hasStyle
    end
    num = ''
  else
    s = ''
#    s += ' <e.' + title + '>' if hasTitle
#    s += ' <e.' + deriv + '>' if hasDeriv
    if hasDeriv
      if hasTitle   # CD-ROM v2.0
        if hasNum && num == '@'   # �h���`
          s += ' <e.##dfn##' + title + '##/dfn##> ' + deriv
          num = '&xSym1;'
        else
          s += ' <e.' + title + '> ' + deriv  # ???
        end
        if hasSubx   # CD-ROM v3.0  1 ���̂�
          s += ' ' + subx
        end
      else          # CD-ROM v1.0
        if hasNum && num == '@'   # �h���`
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
        num = '<b>' + num + '</b> '
      end
    else
      num =  ''
    end

    if s != ''
      s = convert(s).gsub(/##(\/?dfn)##/) { '<' + $1 + '>' }
      f.puts '<p>' + num + s.strip + '</p>'
      num = ''
    end
  end

#  if hasNum && num == '@' && hasDeriv
#    f.puts '<key type="�\�L">' + convert(deriv).strip + '</key>'
#  end

  if hasNote
    f.puts '<p>' + convert(note) + '</p>'
  end

  if hasMeaning
    f.puts '<p>' + num + convert(meaning) + '</p>'
    num = ''
  end

  if hasTable
    f.puts '<p>' + num + '</p>' if num != ''
    table.each { |v|
                                # �ŏ��� <li> ���폜
      f.puts '<p>' + convert('<e.' + v.sub(/<li>/, '') + '>') + '</p>'
    }
  end

  if hasExample
    f.puts '<p>' + num + '</p>' if num != ''
    num = ''
    example.each { |v|
      f.puts '<p>' + PrefixExample + convert(v) + '</p>' unless v.empty?
    }
  end

  if hasXRef
    f.puts '<p>' + num + '</p>' if num != ''
    num = ''
    xref.each { |v|
      f.puts '<p>' + convert(v) + '</p>'
    }
  end

  # CD-ROM v3.0
  if hasSeeAlso
    f.puts '<p>' + convert(seealso) + '</p>'
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
    f.puts '<p>' + num + s.strip + '</p>'
    num = ''
  end

  ## ���̏ꏊ�ł�����
  if hasSynonym
    a = convert(synonym).split(',')
    a.each { |v|
      f.puts '<key type="����">' + v.strip + '</key>'
    }
  end

  if hasAntonym
    a = convert(antonym).split(',')
    a.each { |v|
      f.puts '<key type="����">' + v.strip + '</key>'
    }
  end

  # �i����؂�
  if type == F_Usage || type == F_Grammar
    f.puts '<p></p>'
  end

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

### �擪���R�[�h�𒘍쌠�t�@�C���ɏo��
def printCopyright(fname, type, f, d)

  OutHTML::open(fname, 'w') do |cf|
    cf.writeHeader(Files[type]['title'])
    num = 0
    rec = f.getRec(num)
    d.setData(rec)
    items = d.getc               # �{�����ڐ�
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
    items = d.getc               # �{�����ڐ�
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

  STDERR.print Files[type]['title'], ' ���o�͂��Ă��܂�...', "\n"

  CobuildFile.open(fname, 'rb') do |f|
    f.init
    f.makeIndex

    # ���쌠�t�@�C���o��
    copyrightFname = changeDirAndExt(fname, outDir, CopyrightExt)
    printCopyright(copyrightFname, type, f, d)

    # �{�̏o��
    max = count = f.recCount - 1
#count = 350

    STDERR.print 0, '/', max, "\r"

    if type == F_Wordbank  # 2 �̃t�@�C���ɕ������ďo��
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

  STDERR.print Files[F_Image]['title'], ' ���o�͂��Ă��܂�...', "\n"
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
  STDERR.print "����: EBStudio �ŕϊ������s����O��\n#{imgDir} �ɂ��� .gif �t�@�C���� .jpg �t�@�C���ɕϊ����Ă�������\n"

end

### --------------------------------------------------------------------
def main(runType, scrPath)

  inDir = ARGV.shift
  inDir = inDir.gsub(/\\/, '/').sub(/\/$/, '')
  outDir = ARGV.shift || '.'
  outDir = outDir.gsub(/\\/, '/').sub(/\/$/, '')

  # �o�[�W��������
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
    STDERR.print "#{inDir} �ɕK�v�ȃt�@�C����������܂���\n"
    exit 3
  end
  # �V�\�[���X���Ȃ���� CD-ROM v3 �Ƃ݂Ȃ�
  if version == '1'
    if not File::exist?(inDir + '/' + Files[F_Thesaurus]['name1'])
      version = '2'
    end
  end

  start = Time::now
  STDERR.print "�J�n����: ", start.strftime('%Y-%m-%d %X'), "\n"

  if runType == T_STANDARD

    # �����o��
    [ F_Dic, F_Thesaurus, F_Usage, F_Grammar].each do |v|
      if Files[v]['name' + version] != ''
        fname = inDir + '/' + Files[v]['name' + version]
        if File::exist?(fname)
          printFile(fname, v, outDir)
        else
          STDERR.print "#{fname}��������܂���\n"
        end
      end
    end

    # �摜�o��
    [ F_Image ].each do |v|
      fname = inDir + '/' + Files[v]['name' + version]
      if File::exist?(fname)
        writeImage(fname, outDir)
      else
        STDERR.print "#{fname}��������܂���\n"
      end
    end

    # ��Ɗ���`�t�@�C���o��
    EBSFile::open(outDir + '/' + EBSFnames[T_STANDARD], 'w') do |f|
      f.printEBS(outDir, version)
    end

  else

    # �����o��
    [ F_Wordbank ].each do |v|
      fname = inDir + '/' + Files[v]['name' + version]
      if File::exist?(fname)
        printFile(fname, v, outDir)
      else
        STDERR.print "#{fname}��������܂���\n"
      end
    end

    # ��Ɗ���`�t�@�C���o��
    WordbankEBSFile::open(outDir + '/' + EBSFnames[T_WORDBANK], 'w') do |f|
      f.printEBS(outDir, version, false)
    end
    WordbankEBSFile::open(outDir + '/' + DivEBSFname, 'w') do |f|
      f.printEBS(outDir, version, true)
    end

  end

  # �O���t�@�C���̃R�s�[
  copyFile(scrPath + '/' + GaiziFname, outDir + '/' + GaiziFname)
  copyFile(scrPath + '/' + GaiziMapFname, outDir + '/' + GaiziMapFname)

  finish = Time::now
  STDERR.print "�I������: ", finish.strftime('%Y-%m-%d %X'), "\n"
  STDERR.print "��������: ", Time::at(finish.to_i - start.to_i).utc.strftime('%X'), "\n"

end

### --------------------------------------------------------------------
main(runType, scrPath)
