import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_athletes/verb_conjugation.dart';

void main() {
  test('ichidan forms are built from the stem', () {
    final forms = ichidanForms('食べる', 'たべる');
    Map<String, String> byLabel = {for (final f in forms) f.label: f.japanese};
    expect(byLabel['Dictionary form'], '食べる');
    expect(byLabel['Negative (nai)'], '食べない');
    expect(byLabel['Past (ta)'], '食べた');
    expect(byLabel['Polite (masu)'], '食べます');
    expect(byLabel['Polite past negative (masen deshita)'], '食べませんでした');
    expect(byLabel['Te form'], '食べて');
    expect(byLabel['After doing (te kara)'], '食べてから');
    expect(byLabel['Doing, in progress (teiru)'], '食べている');
    expect(byLabel['If (ba)'], '食べれば');
    expect(byLabel["If it's the case (nara)"], '食べるなら');
    expect(byLabel['Because (kara)'], '食べるから');
    expect(byLabel["Don't! (prohibitive)"], '食べるな');
    expect(byLabel['Command (imperative)'], '食べろ');
    expect(byLabel['Passive (rareru)'], '食べられる');
    expect(byLabel["Let's, I will (volitional)"], '食べよう');
    expect(byLabel['Make/let someone do (causative)'], '食べさせる');
    expect(byLabel['Start doing (hajimeru)'], '食べ始める');
    expect(byLabel['Keep doing (tsuzukeru)'], '食べ続ける');
    expect(byLabel['Do into, deeply (komu)'], '食べ込む');
    expect(byLabel['Do completely, finish (kiru)'], '食べ切る');
    expect(byLabel['Easy to do (yasui)'], '食べやすい');
    expect(byLabel['Hard to do (nikui)'], '食べにくい');
    expect(byLabel['Go to do (ni iku)'], '食べに行く');
    final niiku = forms.firstWhere((f) => f.label == 'Go to do (ni iku)');
    expect(niiku.reading, 'たべにいく');

    // Readings track the same stem.
    final te = forms.firstWhere((f) => f.label == 'Te form');
    expect(te.reading, 'たべて');
    expect(te.note, isNotEmpty);
    expect(forms.firstWhere((f) => f.label == 'Negative (nai)').note, isEmpty);
  });

  test('not a verb that ends in る gives no forms', () {
    expect(ichidanForms('飲む', 'のむ'), isEmpty);
    expect(ichidanForms('る', 'る'), isEmpty);
  });

  test('godan forms soften for て/た depending on the ending kana', () {
    String form(String label, String japanese, String reading) =>
        godanForms(japanese, reading).firstWhere((f) => f.label == label).japanese;

    // む, く, す, う, ぐ, つ, ぬ, ぶ, る - one representative of each group.
    expect(form('Te form', '読む', 'よむ'), '読んで');
    expect(form('Past (ta)', '読む', 'よむ'), '読んだ');
    expect(form('Te form', '書く', 'かく'), '書いて');
    expect(form('Te form', '話す', 'はなす'), '話して');
    expect(form('Te form', '買う', 'かう'), '買って');
    expect(form('Negative (nai)', '買う', 'かう'), '買わない'); // わ, not あ
    expect(form('Te form', '泳ぐ', 'およぐ'), '泳いで');
    expect(form('Te form', '待つ', 'まつ'), '待って');
    expect(form('Te form', '死ぬ', 'しぬ'), '死んで');
    expect(form('Te form', '遊ぶ', 'あそぶ'), '遊んで');
    expect(form('Te form', '乗る', 'のる'), '乗って');

    // 行く is the one common exception: って/った like an う/つ/る verb,
    // not いて/いた like every other く verb (e.g. 書いて above).
    expect(form('Te form', '行く', 'いく'), '行って');
    expect(form('Past (ta)', '行く', 'いく'), '行った');
    expect(form('Negative (nai)', '行く', 'いく'), '行かない'); // regular く row elsewhere
    expect(form('Command (imperative)', '行く', 'いく'), '行け');

    final yomu = godanForms('読む', 'よむ');
    Map<String, String> byLabel = {for (final f in yomu) f.label: f.japanese};
    expect(byLabel['Polite (masu)'], '読みます');
    expect(byLabel['If (ba)'], '読めば');
    expect(byLabel['Passive (reru)'], '読まれる');
    expect(byLabel['Potential, can do (eru)'], '読める');
    expect(byLabel["Let's, I will (volitional)"], '読もう');
    expect(byLabel['Causative (seru)'], '読ませる');
    expect(byLabel['Among other things (tari)'], '読んだり');
    expect(byLabel['Go to do (ni iku)'], '読みに行く');
    final goTo = yomu.firstWhere((f) => f.label == 'Go to do (ni iku)');
    expect(goTo.reading, 'よみにいく');
  });

  test('the five honorific godan る-verbs use い, not り/れ, for masu and the imperative', () {
    Map<String, String> byLabel(List<VerbForm> forms) => {for (final f in forms) f.label: f.japanese};

    final gozaru = byLabel(godanForms('ござる', 'ござる'));
    expect(gozaru['Polite (masu)'], 'ございます');
    expect(gozaru['Polite negative (masen)'], 'ございません');

    final kudasaru = byLabel(godanForms('下さる', 'くださる'));
    expect(kudasaru['Polite (masu)'], '下さいます');
    expect(kudasaru['Command (imperative)'], '下さい');
    expect(kudasaru['Negative (nai)'], '下さらない'); // regular ら, not special

    final irassharu = byLabel(godanForms('いらっしゃる', 'いらっしゃる'));
    expect(irassharu['Polite (masu)'], 'いらっしゃいます');
    expect(irassharu['Command (imperative)'], 'いらっしゃい');
    expect(irassharu['Te form'], 'いらっしゃって'); // regular って, not special

    final ossharu = byLabel(godanForms('仰る', 'おっしゃる'));
    expect(ossharu['Polite (masu)'], '仰います');
    expect(ossharu['Command (imperative)'], '仰い');

    final nasaru = byLabel(godanForms('なさる', 'なさる'));
    expect(nasaru['Polite (masu)'], 'なさいます');
    expect(nasaru['Command (imperative)'], 'なさい');
    expect(nasaru['Please do (nasai)'], 'なさいなさい'); // the generic なさい suffix, on top of its own い-row
  });

  test('aru suppletes to nai rather than aranai', () {
    final aru = {for (final f in godanForms('ある', 'ある')) f.label: f.japanese};
    expect(aru['Negative (nai)'], 'ない'); // not あらない
    expect(aru['Past negative (nakatta)'], 'なかった');
    expect(aru['Without doing (naide)'], 'ないで');
    expect(aru["Don't have to (nakutemoii)"], 'なくてもいい');
    // Everything else about ある is completely regular.
    expect(aru['Polite (masu)'], 'あります');
    expect(aru['Te form'], 'あって');
    expect(aru['If (ba)'], 'あれば');
  });

  test('kureru has an irregular bare-stem imperative, くれ not くれろ', () {
    final kureru = {for (final f in ichidanForms('くれる', 'くれる')) f.label: f.japanese};
    expect(kureru['Command (imperative)'], 'くれ');
    expect(kureru['Negative (nai)'], 'くれない'); // otherwise fully regular ichidan

    final kanjiForm = {for (final f in ichidanForms('呉れる', 'くれる')) f.label: f.japanese};
    expect(kanjiForm['Command (imperative)'], '呉れ');
  });

  test('tou/kou verbs keep うて/うた instead of taking female っ', () {
    final tou = {for (final f in godanForms('問う', 'とう')) f.label: f.japanese};
    expect(tou['Te form'], '問うて'); // not 問って
    expect(tou['Past (ta)'], '問うた'); // not 問った
    expect(tou['Among other things (tari)'], '問うたり');
    expect(tou['Negative (nai)'], '問わない'); // otherwise fully regular う-row

    final kou = {for (final f in godanForms('請う', 'こう')) f.label: f.japanese};
    expect(kou['Te form'], '請うて');
    expect(kou['Past (ta)'], '請うた');
  });

  test('an ordinary る-godan verb is unaffected by the honorific special case', () {
    final noru = godanForms('乗る', 'のる');
    final byLabel = {for (final f in noru) f.label: f.japanese};
    expect(byLabel['Polite (masu)'], '乗ります');
    expect(byLabel['Command (imperative)'], '乗れ');
  });

  test('godan forms are empty for a word that is too short or mismatched', () {
    expect(godanForms('く', 'く'), isEmpty);
    expect(godanForms('読む', 'よく'), isEmpty); // japanese/reading endings disagree
  });

  test('suru verbs mix し/さ/す/でき depending on the form', () {
    Map<String, String> byLabel(List<VerbForm> forms) => {for (final f in forms) f.label: f.japanese};
    final suru = byLabel(irregularForms('する', 'する'));
    expect(suru['Dictionary form'], 'する');
    expect(suru['Negative (nai)'], 'しない');
    expect(suru['Te form'], 'して');
    expect(suru['If (ba)'], 'すれば'); // す, not し
    expect(suru['Passive (reru)'], 'される'); // さ, not し
    expect(suru['Potential, can do (dekiru)'], 'できる'); // replaces する entirely
    expect(suru['Causative (seru)'], 'させる'); // さ, not し

    // A compound する verb (愛する) conjugates the same way, on its own stem.
    final aisuru = byLabel(irregularForms('愛する', 'あいする'));
    expect(aisuru['Negative (nai)'], '愛しない');
    expect(aisuru['Passive (reru)'], '愛される');
    final aisuruReading = irregularForms('愛する', 'あいする').firstWhere((f) => f.label == 'Negative (nai)');
    expect(aisuruReading.reading, 'あいしない');
  });

  test('kuru verbs move the く between こ/き/く and have their own imperative', () {
    Map<String, String> byLabel(List<VerbForm> forms) => {for (final f in forms) f.label: f.japanese};
    final kuru = byLabel(irregularForms('来る', 'くる'));
    expect(kuru['Dictionary form'], '来る');
    expect(kuru['Negative (nai)'], '来ない'); // こ
    expect(kuru['Te form'], '来て'); // き
    expect(kuru['If (ba)'], '来れば'); // く
    expect(kuru['Command (imperative)'], '来い'); // irregular, not 来ろ
    expect(kuru.containsKey('Go to do (ni iku)'), isFalse); // 来るに行く would be nonsense
    final kuruReading = irregularForms('来る', 'くる').firstWhere((f) => f.label == 'Negative (nai)');
    expect(kuruReading.reading, 'こない');

    // A compound kuru verb (やって来る) conjugates the same way.
    final yattekuru = byLabel(irregularForms('やって来る', 'やってくる'));
    expect(yattekuru['Negative (nai)'], 'やって来ない');
    expect(yattekuru['Command (imperative)'], 'やって来い');
  });

  test('irregular forms are empty for a verb that is neither suru nor kuru', () {
    expect(irregularForms('読む', 'よむ'), isEmpty);
  });

  test('i-adjective forms are built from the stem', () {
    final forms = iAdjectiveForms('高い', 'たかい');
    Map<String, String> byLabel = {for (final f in forms) f.label: f.japanese};
    expect(byLabel['Dictionary form'], '高い');
    expect(byLabel['Negative (kunai)'], '高くない');
    expect(byLabel['Past (katta)'], '高かった');
    expect(byLabel['Past negative (kunakatta)'], '高くなかった');
    expect(byLabel['Te form'], '高くて');
    expect(byLabel['Adverb (ku)'], '高く');
    expect(byLabel['If (kereba)'], '高ければ');
    expect(byLabel["If it's the case (nara)"], '高いなら');
    expect(byLabel['Because (kara)'], '高いから');
    expect(byLabel['Becomes ... (kunaru)'], '高くなる');
    expect(byLabel['Looks like (sou)'], '高そう'); // regular adjective: no さ
    expect(byLabel['Too ... (sugiru)'], '高すぎる');
    expect(byLabel['Degree, -ness (sa)'], '高さ');
  });

  test('ii/yoi and nai take さそう instead of plain そう', () {
    final ii = iAdjectiveForms('いい', 'いい');
    final iiByLabel = {for (final f in ii) f.label: f.japanese};
    expect(iiByLabel['Negative (kunai)'], 'よくない'); // conjugates from よい, not い
    expect(iiByLabel['Past (katta)'], 'よかった');
    expect(iiByLabel['Looks like (sou)'], 'よさそう');

    final yoi = iAdjectiveForms('良い', 'よい');
    final yoiByLabel = {for (final f in yoi) f.label: f.japanese};
    expect(yoiByLabel['Negative (kunai)'], '良くない');
    expect(yoiByLabel['Looks like (sou)'], '良さそう');

    final nai = iAdjectiveForms('ない', 'ない');
    final naiByLabel = {for (final f in nai) f.label: f.japanese};
    expect(naiByLabel['Looks like (sou)'], 'なさそう');
  });

  test('i-adjective forms are empty for a word that does not end in い', () {
    expect(iAdjectiveForms('読む', 'よむ'), isEmpty);
  });
}
