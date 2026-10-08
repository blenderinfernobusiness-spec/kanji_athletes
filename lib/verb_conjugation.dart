// One conjugated form of a verb: a short label, the written form, its
// reading (for furigana - see rubyWord in ruby_text.dart), and an optional
// note for a form that's used for more than its main meaning.
class VerbForm {
  final String label;
  final String japanese;
  final String reading;
  final String note;

  const VerbForm(this.label, this.japanese, this.reading, {this.note = ''});
}

// The conjugated forms of an ichidan verb, built from its stem - everything
// before the dictionary-form る, which never changes for ichidan verbs (食べる
// -> 食べ-). Only meaningful for ichidan verbs; godan verbs conjugate
// differently and need their own generator.
//
// kara and nara attach after the plain dictionary form rather than the stem
// (食べるから, not 食べから); the prohibitive な does too (食べるな).
List<VerbForm> ichidanForms(String japanese, String reading) {
  if (japanese.length < 2 || reading.length < 2 || !japanese.endsWith('る') || !reading.endsWith('る')) {
    return const [];
  }
  final s = japanese.substring(0, japanese.length - 1);
  final r = reading.substring(0, reading.length - 1);
  VerbForm stem(String label, String ending, {String note = ''}) =>
      VerbForm(label, '$s$ending', '$r$ending', note: note);
  // For an ending that's spelled differently from how it reads (an ending
  // with its own kanji, like 込む/こむ), unlike ない or ます which are the same.
  VerbForm stemText(String label, String jEnding, String rEnding) => VerbForm(label, '$s$jEnding', '$r$rEnding');
  VerbForm plain(String label, String ending) => VerbForm(label, '$japanese$ending', '$reading$ending');
  // くれる's imperative is irregularly just くれ (the bare stem), not くれろ -
  // the one form where this otherwise entirely regular ichidan verb breaks.
  final isKureru = reading == 'くれる';
  return [
    VerbForm('Dictionary form', japanese, reading),
    stem('Negative (nai)', 'ない'),
    stem('Past (ta)', 'た'),
    stem('Past negative (nakatta)', 'なかった'),
    stem('Polite (masu)', 'ます'),
    stem('Polite negative (masen)', 'ません'),
    stem('Polite past (mashita)', 'ました'),
    stem('Polite past negative (masen deshita)', 'ませんでした'),
    stem('Want to (tai)', 'たい'),
    stem("Don't want to (takunai)", 'たくない'),
    stem('Wanted to (takatta)', 'たかった'),
    stem("Didn't want to (takunakatta)", 'たくなかった'),
    stem(
      'Te form',
      'て',
      note: 'Also a casual request ("Can I ...?") or links two actions ("... and ...").',
    ),
    stem('After doing (te kara)', 'てから'),
    stem('Without doing (naide)', 'ないで'),
    stem('Doing, in progress (teiru)', 'ている'),
    stem('Not doing (teinai)', 'ていない'),
    stem('Was doing (teita)', 'ていた'),
    stem('Among other things (tari)', 'たり'),
    stem('If (ba)', 'れば'),
    stem('If, when (tara)', 'たら'),
    plain("If it's the case (nara)", 'なら'),
    plain('Because (kara)', 'から'),
    stem("May, it's okay to (temoii)", 'てもいい'),
    stem("Don't have to (nakutemoii)", 'なくてもいい'),
    stem('Command (imperative)', isKureru ? '' : 'ろ'),
    plain("Don't! (prohibitive)", 'な'),
    stem('Please do (nasai)', 'なさい'),
    stem('Passive (rareru)', 'られる'),
    stem('Potential, can do (rareru)', 'られる'),
    stem("Let's, I will (volitional)", 'よう'),
    stem('Make/let someone do (causative)', 'させる'),
    stem('Be made to do (causative-passive)', 'させられる'),
    stem('Looks like (sou)', 'そう'),
    // Compound verbs: a second verb (itself conjugatable) attached to the
    // stem to build a single idea, like 食べ始める (start eating).
    stemText('Start doing (hajimeru)', '始める', 'はじめる'),
    stemText('Finish doing (owaru)', '終わる', 'おわる'),
    stemText('Keep doing (tsuzukeru)', '続ける', 'つづける'),
    stemText('Keep doing, polite (tsuzukemasu)', '続けます', 'つづけます'),
    stemText('Start doing suddenly (dasu)', '出す', 'だす'),
    stemText('Do too much (sugiru)', '過ぎる', 'すぎる'),
    stemText('Do into, deeply (komu)', '込む', 'こむ'),
    stemText('Do completely, finish (kiru)', '切る', 'きる'),
    stem('Start to, half-done (kakeru)', 'かける'),
    stemText('Redo, fix (naosu)', '直す', 'なおす'),
    stem('Easy to do (yasui)', 'やすい'),
    stem('Hard to do (nikui)', 'にくい'),
    stemText('Go to do (ni iku)', 'に行く', 'にいく'),
    stemText('Come to do (ni kuru)', 'に来る', 'にくる'),
  ];
}

// How a godan verb's dictionary-form ending kana maps to its other rows -
// used for ない/ます/ば/the volitional, etc. - and to how て/た attach. Unlike
// ichidan, the ending itself changes (読む -> 読ま/読み/読め/読も), and て/た
// soften the final consonant together (読んで, not 読むて) rather than just
// following it.
class _GodanRow {
  final String a; // ない, れる, せる (わ for う)
  final String i; // ます, たい, and the compound verbs below
  final String e; // ば, the imperative, the -eru potential
  final String o; // the volitional
  final String te; // replaces the dictionary ending for て
  final String ta; // replaces the dictionary ending for た

  const _GodanRow(this.a, this.i, this.e, this.o, this.te, this.ta);
}

// ございる (usually spelled ござる), いらっしゃる, くださる, おっしゃる and
// なさる - honorific godan る-verbs with their own irregular い-row and
// imperative; see the note in godanForms.
const Set<String> _specialHonorificGodan = {'ござる', 'いらっしゃる', 'くださる', 'おっしゃる', 'なさる'};

const Map<String, _GodanRow> _godanRows = {
  'う': _GodanRow('わ', 'い', 'え', 'お', 'って', 'った'),
  'く': _GodanRow('か', 'き', 'け', 'こ', 'いて', 'いた'),
  'ぐ': _GodanRow('が', 'ぎ', 'げ', 'ご', 'いで', 'いだ'),
  'す': _GodanRow('さ', 'し', 'せ', 'そ', 'して', 'した'),
  'つ': _GodanRow('た', 'ち', 'て', 'と', 'って', 'った'),
  'ぬ': _GodanRow('な', 'に', 'ね', 'の', 'んで', 'んだ'),
  'ぶ': _GodanRow('ば', 'び', 'べ', 'ぼ', 'んで', 'んだ'),
  'む': _GodanRow('ま', 'み', 'め', 'も', 'んで', 'んだ'),
  'る': _GodanRow('ら', 'り', 'れ', 'ろ', 'って', 'った'),
};

// The conjugated forms of a godan verb. 行く is the one common exception:
// its て/た take って/った like an う/つ/る verb, instead of the いて/いた its
// く ending would otherwise give it (so 聞く -> 聞いて, but 行く -> 行って).
//
// Passive, potential and causative are genuinely different shapes for godan
// (れる/-eru/せる) rather than ichidan's られる/させる doing double duty, so
// their labels spell out the actual ending instead of reusing ichidan's.
List<VerbForm> godanForms(String japanese, String reading) {
  if (japanese.length < 2 || reading.length < 2) return const [];
  final lastKana = reading[reading.length - 1];
  if (japanese[japanese.length - 1] != lastKana) return const [];
  final row = _godanRows[lastKana];
  if (row == null) return const [];
  final isIku = japanese.endsWith('行く') && reading.endsWith('いく');
  // 問う/請う/乞う/恋う keep their classical うて/うた instead of taking the
  // female っ every other う-ending godan verb takes (買う -> 買って, but
  // 問う -> 問うて, not 問って).
  final keepsUteUta = reading == 'とう' || reading == 'こう';
  final te = isIku ? 'って' : (keepsUteUta ? 'うて' : row.te);
  final ta = isIku ? 'った' : (keepsUteUta ? 'うた' : row.ta);
  // These five are honorific godan る-verbs whose い-row and imperative are
  // both い rather than the regular り/れ - ございます/くださいます/
  // いらっしゃいます/おっしゃいます/なさいます, and ください/なさい/いらっしゃい/
  // おっしゃい as the imperative. Everything else about them (ない, て/た, ば,
  // the volitional, ...) is a completely regular る-group godan verb
  // (くださらない, くださって, くだされば, ...).
  final isSpecialHonorific = _specialHonorificGodan.contains(reading);
  final iRow = isSpecialHonorific ? 'い' : row.i;
  final imperativeEnding = isSpecialHonorific ? 'い' : row.e;

  final s = japanese.substring(0, japanese.length - 1);
  final r = reading.substring(0, reading.length - 1);
  VerbForm build(String label, String ending, {String note = ''}) =>
      VerbForm(label, '$s$ending', '$r$ending', note: note);
  VerbForm buildText(String label, String jEnding, String rEnding) =>
      VerbForm(label, '$s$jEnding', '$r$rEnding');
  VerbForm plain(String label, String ending) => VerbForm(label, '$japanese$ending', '$reading$ending');
  // ある's plain negative isn't あらない - it's suppletive, replacing the whole
  // word with ない (and なかった, ないで, なくてもいい), dropping even あ itself.
  final isAru = reading == 'ある';
  VerbForm naiForm(String label, String ending) =>
      isAru ? VerbForm(label, ending, ending) : build(label, '${row.a}$ending');

  return [
    VerbForm('Dictionary form', japanese, reading),
    naiForm('Negative (nai)', 'ない'),
    build('Past (ta)', ta),
    naiForm('Past negative (nakatta)', 'なかった'),
    build('Polite (masu)', '$iRowます'),
    build('Polite negative (masen)', '$iRowません'),
    build('Polite past (mashita)', '$iRowました'),
    build('Polite past negative (masen deshita)', '$iRowませんでした'),
    build('Want to (tai)', '$iRowたい'),
    build("Don't want to (takunai)", '$iRowたくない'),
    build('Wanted to (takatta)', '$iRowたかった'),
    build("Didn't want to (takunakatta)", '$iRowたくなかった'),
    build('Te form', te, note: 'Also a casual request ("Can I ...?") or links two actions ("... and ...").'),
    build('After doing (te kara)', '$teから'),
    naiForm('Without doing (naide)', 'ないで'),
    build('Doing, in progress (teiru)', '$teいる'),
    build('Not doing (teinai)', '$teいない'),
    build('Was doing (teita)', '$teいた'),
    build('Among other things (tari)', '$taり'),
    build('If (ba)', '${row.e}ば'),
    build('If, when (tara)', '$taら'),
    plain("If it's the case (nara)", 'なら'),
    plain('Because (kara)', 'から'),
    build("May, it's okay to (temoii)", '$teもいい'),
    naiForm("Don't have to (nakutemoii)", 'なくてもいい'),
    build('Command (imperative)', imperativeEnding),
    plain("Don't! (prohibitive)", 'な'),
    build('Please do (nasai)', '$iRowなさい'),
    build('Passive (reru)', '${row.a}れる'),
    build('Potential, can do (eru)', '${row.e}る'),
    build("Let's, I will (volitional)", '${row.o}う'),
    build('Causative (seru)', '${row.a}せる'),
    build('Causative-passive (serareru)', '${row.a}せられる'),
    build('Looks like (sou)', '$iRowそう'),
    buildText('Start doing (hajimeru)', '$iRow始める', '$iRowはじめる'),
    buildText('Finish doing (owaru)', '$iRow終わる', '$iRowおわる'),
    buildText('Keep doing (tsuzukeru)', '$iRow続ける', '$iRowつづける'),
    buildText('Keep doing, polite (tsuzukemasu)', '$iRow続けます', '$iRowつづけます'),
    buildText('Start doing suddenly (dasu)', '$iRow出す', '$iRowだす'),
    buildText('Do too much (sugiru)', '$iRow過ぎる', '$iRowすぎる'),
    buildText('Do into, deeply (komu)', '$iRow込む', '$iRowこむ'),
    buildText('Do completely, finish (kiru)', '$iRow切る', '$iRowきる'),
    build('Start to, half-done (kakeru)', '$iRowかける'),
    buildText('Redo, fix (naosu)', '$iRow直す', '$iRowなおす'),
    build('Easy to do (yasui)', '$iRowやすい'),
    build('Hard to do (nikui)', '$iRowにくい'),
    buildText('Go to do (ni iku)', '$iRowに行く', '$iRowにいく'),
    buildText('Come to do (ni kuru)', '$iRowに来る', '$iRowにくる'),
  ];
}

const String _teNote = 'Also a casual request ("Can I ...?") or links two actions ("... and ...").';

// The two irregular verbs, 来る (kuru) and する (suru), and every word built
// from them (愛する, やって来る, 持ってくる, ...). Neither follows the ichidan
// or godan pattern: する swaps between し/さ/す/でき depending on the form, and
// 来る keeps its reading's く but moves it between こ/き/く irregularly (来い,
// not 来ろ; 来れば, not usable the ichidan way either).
List<VerbForm> irregularForms(String japanese, String reading) {
  if (japanese.endsWith('する') && reading.endsWith('する')) {
    return _suruForms(japanese.substring(0, japanese.length - 2), reading.substring(0, reading.length - 2));
  }
  if (japanese.endsWith('来る') && reading.endsWith('くる')) {
    return _kuruForms(japanese.substring(0, japanese.length - 2), reading.substring(0, reading.length - 2));
  }
  if (japanese.endsWith('くる') && reading.endsWith('くる')) {
    return _kuruForms(japanese.substring(0, japanese.length - 2), reading.substring(0, reading.length - 2));
  }
  return const [];
}

List<VerbForm> _suruForms(String s, String r) {
  VerbForm f(String label, String jEnd, String rEnd, {String note = ''}) =>
      VerbForm(label, '$s$jEnd', '$r$rEnd', note: note);
  final dictJ = '$sする';
  final dictR = '$rする';
  return [
    VerbForm('Dictionary form', dictJ, dictR),
    f('Negative (nai)', 'しない', 'しない'),
    f('Past (ta)', 'した', 'した'),
    f('Past negative (nakatta)', 'しなかった', 'しなかった'),
    f('Polite (masu)', 'します', 'します'),
    f('Polite negative (masen)', 'しません', 'しません'),
    f('Polite past (mashita)', 'しました', 'しました'),
    f('Polite past negative (masen deshita)', 'しませんでした', 'しませんでした'),
    f('Want to (tai)', 'したい', 'したい'),
    f("Don't want to (takunai)", 'したくない', 'したくない'),
    f('Wanted to (takatta)', 'したかった', 'したかった'),
    f("Didn't want to (takunakatta)", 'したくなかった', 'したくなかった'),
    f('Te form', 'して', 'して', note: _teNote),
    f('After doing (te kara)', 'してから', 'してから'),
    f('Without doing (naide)', 'しないで', 'しないで'),
    f('Doing, in progress (teiru)', 'している', 'している'),
    f('Not doing (teinai)', 'していない', 'していない'),
    f('Was doing (teita)', 'していた', 'していた'),
    f('Among other things (tari)', 'したり', 'したり'),
    f('If (ba)', 'すれば', 'すれば'), // す, not し - the one exception within する itself
    f('If, when (tara)', 'したら', 'したら'),
    VerbForm("If it's the case (nara)", '$dictJなら', '$dictRなら'),
    VerbForm('Because (kara)', '$dictJから', '$dictRから'),
    f("May, it's okay to (temoii)", 'してもいい', 'してもいい'),
    f("Don't have to (nakutemoii)", 'しなくてもいい', 'しなくてもいい'),
    f('Command (imperative)', 'しろ', 'しろ'),
    VerbForm("Don't! (prohibitive)", '$dictJな', '$dictRな'),
    f('Please do (nasai)', 'しなさい', 'しなさい'),
    f('Passive (reru)', 'される', 'される'), // さ, not し
    f('Potential, can do (dekiru)', 'できる', 'できる'), // replaces する entirely
    f("Let's, I will (volitional)", 'しよう', 'しよう'),
    f('Causative (seru)', 'させる', 'させる'), // さ, not し
    f('Causative-passive (serareru)', 'させられる', 'させられる'),
    f('Looks like (sou)', 'しそう', 'しそう'),
    f('Start doing (hajimeru)', 'し始める', 'しはじめる'),
    f('Finish doing (owaru)', 'し終わる', 'しおわる'),
    f('Keep doing (tsuzukeru)', 'し続ける', 'しつづける'),
    f('Keep doing, polite (tsuzukemasu)', 'し続けます', 'しつづけます'),
    f('Start doing suddenly (dasu)', 'し出す', 'しだす'),
    f('Do too much (sugiru)', 'しすぎる', 'しすぎる'),
    f('Do into, deeply (komu)', 'し込む', 'しこむ'),
    f('Do completely, finish (kiru)', 'し切る', 'しきる'),
    f('Start to, half-done (kakeru)', 'しかける', 'しかける'),
    f('Redo, fix (naosu)', 'し直す', 'しなおす'),
    f('Easy to do (yasui)', 'しやすい', 'しやすい'),
    f('Hard to do (nikui)', 'しにくい', 'しにくい'),
    f('Go to do (ni iku)', 'しに行く', 'しにいく'),
    f('Come to do (ni kuru)', 'しに来る', 'しにくる'),
  ];
}

List<VerbForm> _kuruForms(String s, String r) {
  VerbForm f(String label, String jEnd, String rEnd, {String note = ''}) =>
      VerbForm(label, '$s$jEnd', '$r$rEnd', note: note);
  final dictJ = '$s来る';
  final dictR = '$rくる';
  return [
    VerbForm('Dictionary form', dictJ, dictR),
    f('Negative (nai)', '来ない', 'こない'),
    f('Past (ta)', '来た', 'きた'),
    f('Past negative (nakatta)', '来なかった', 'こなかった'),
    f('Polite (masu)', '来ます', 'きます'),
    f('Polite negative (masen)', '来ません', 'きません'),
    f('Polite past (mashita)', '来ました', 'きました'),
    f('Polite past negative (masen deshita)', '来ませんでした', 'きませんでした'),
    f('Want to (tai)', '来たい', 'きたい'),
    f("Don't want to (takunai)", '来たくない', 'きたくない'),
    f('Wanted to (takatta)', '来たかった', 'きたかった'),
    f("Didn't want to (takunakatta)", '来たくなかった', 'きたくなかった'),
    f('Te form', '来て', 'きて', note: _teNote),
    f('After doing (te kara)', '来てから', 'きてから'),
    f('Without doing (naide)', '来ないで', 'こないで'),
    f('Doing, in progress (teiru)', '来ている', 'きている'),
    f('Not doing (teinai)', '来ていない', 'きていない'),
    f('Was doing (teita)', '来ていた', 'きていた'),
    f('Among other things (tari)', '来たり', 'きたり'),
    f('If (ba)', '来れば', 'くれば'), // く, not き
    f('If, when (tara)', '来たら', 'きたら'),
    VerbForm("If it's the case (nara)", '$dictJなら', '$dictRなら'),
    VerbForm('Because (kara)', '$dictJから', '$dictRから'),
    f("May, it's okay to (temoii)", '来てもいい', 'きてもいい'),
    f("Don't have to (nakutemoii)", '来なくてもいい', 'こなくてもいい'),
    f('Command (imperative)', '来い', 'こい'), // irregular - not 来ろ
    VerbForm("Don't! (prohibitive)", '$dictJな', '$dictRな'),
    f('Please do (nasai)', '来なさい', 'きなさい'),
    f('Passive (rareru)', '来られる', 'こられる'),
    f('Potential, can do (rareru)', '来られる', 'こられる'),
    f("Let's, I will (volitional)", '来よう', 'こよう'),
    f('Causative (saseru)', '来させる', 'こさせる'),
    f('Causative-passive (saserareru)', '来させられる', 'こさせられる'),
    f('Looks like (sou)', '来そう', 'きそう'),
    f('Start doing (hajimeru)', '来始める', 'きはじめる'),
    f('Finish doing (owaru)', '来終わる', 'きおわる'),
    f('Keep doing (tsuzukeru)', '来続ける', 'きつづける'),
    f('Keep doing, polite (tsuzukemasu)', '来続けます', 'きつづけます'),
    f('Start doing suddenly (dasu)', '来出す', 'きだす'),
    f('Do too much (sugiru)', '来すぎる', 'きすぎる'),
    f('Do into, deeply (komu)', '来込む', 'きこむ'),
    f('Do completely, finish (kiru)', '来切る', 'ききる'),
    f('Start to, half-done (kakeru)', '来かける', 'きかける'),
    f('Redo, fix (naosu)', '来直す', 'きなおす'),
    f('Easy to do (yasui)', '来やすい', 'きやすい'),
    f('Hard to do (nikui)', '来にくい', 'きにくい'),
    // ni iku/ni kuru are left out: "来るに行く"/"来るに来る" would be nonsense,
    // since 来る already means "come" (kept for する, where they're natural).
  ];
}

// The conjugated forms of an i-adjective, built from its stem - everything
// before the dictionary-form い (高い -> 高-). いい/よい ("good") and ない
// ("nonexistent") are the two irregularities: いい conjugates as if it were
// よい (よくない, not いくない), and both of them take さそう rather than plain
// そう for "looks ...” (よさそう, なさそう - the rest of their forms are regular).
List<VerbForm> iAdjectiveForms(String japanese, String reading) {
  if (japanese.length < 2 || reading.length < 2 || !japanese.endsWith('い') || !reading.endsWith('い')) {
    return const [];
  }
  var s = japanese.substring(0, japanese.length - 1);
  var r = reading.substring(0, reading.length - 1);
  if (japanese == 'いい') s = 'よ';
  if (reading == 'いい') r = 'よ';
  final takesSaSou = reading == 'いい' || reading == 'よい' || reading == 'ない';
  final souEnding = takesSaSou ? 'さそう' : 'そう';

  VerbForm build(String label, String ending, {String note = ''}) =>
      VerbForm(label, '$s$ending', '$r$ending', note: note);
  VerbForm plain(String label, String ending) => VerbForm(label, '$japanese$ending', '$reading$ending');

  return [
    VerbForm('Dictionary form', japanese, reading),
    build('Negative (kunai)', 'くない'),
    build('Past (katta)', 'かった'),
    build('Past negative (kunakatta)', 'くなかった'),
    build(
      'Te form',
      'くて',
      note: 'Also gives a reason ("..., so ...") or links two descriptions ("... and ...").',
    ),
    build('Negative te form (kunakute)', 'くなくて'),
    build('Adverb (ku)', 'く'),
    build('If (kereba)', 'ければ'),
    build('If not (kunakereba)', 'くなければ'),
    plain("If it's the case (nara)", 'なら'),
    plain('Because (kara)', 'から'),
    plain('Polite (desu)', 'です'),
    build('Polite negative (kunaidesu)', 'くないです'),
    build('Polite negative, formal (kuarimasen)', 'くありません'),
    build('Polite past (kattadesu)', 'かったです'),
    build('Polite past negative (kunakattadesu)', 'くなかったです'),
    build('Becomes ... (kunaru)', 'くなる'),
    build('Looks like (sou)', souEnding),
    build('Too ... (sugiru)', 'すぎる'),
    build('Degree, -ness (sa)', 'さ'),
    build('A bit more ... (me)', 'め'),
  ];
}
