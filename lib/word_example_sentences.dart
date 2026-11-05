import 'tatoeba_service.dart';

// Hand-picked real Tatoeba sentences (3 each) for select dictionary words -
// all 202 of Essential Vocabulary (see sets_data.dart), plus other sets as
// they get the same treatment - kept hardcoded/offline rather than fetched
// live like the rest of the dictionary's sentences (tatoeba_service.dart),
// so these words always have good examples ready instantly, with no
// network round-trip and no chance of an empty/odd result. Not meant to
// cover the whole dictionary - everywhere else still uses the live "Load
// sentence from Tatoeba" fetch. Keyed by the word's japanese text, same as
// getTatoebaSentencesFor's own cache key, so a word shared by two sets
// (e.g. Essential Vocabulary's and JLPT N5's own 自分) only needs one entry
// here. Every sentence keeps its real Tatoeba id/username/license for the
// same per-sentence attribution tatoeba_service.dart requires.
final Map<String, List<TatoebaSentence>> kWordExampleSentences = {
  '私': [
    TatoebaSentence(id: 13611135, text: '私ですか？', translation: "Me?", username: 'stao', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11846527, text: '次は、私？', translation: "Am I next?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8539521, text: '私の失敗？', translation: "Is that my fault?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'あなた': [
    TatoebaSentence(id: 231724, text: 'あなたは朝型？', translation: "Would you say you're a morning person?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1110588, text: 'あなたはどう？', translation: "How about you?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11029625, text: 'あなたの本？', translation: "Is the book yours?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '何': [
    TatoebaSentence(id: 630583, text: '何？', translation: "What?", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 370955, text: '何これ？', translation: "What is this?", username: 'saeb', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10296418, text: '何事？', translation: "Is something happening?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'だ': [
    TatoebaSentence(id: 175405, text: '嫌だ！', translation: "No!", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8858176, text: '猫だ！', translation: "Cat!", username: 'moxy', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13543260, text: '火だ！', translation: "Fire!", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
  ],
  'です': [
    TatoebaSentence(id: 9842777, text: 'そうです！', translation: "That's right!", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9665549, text: '夜です。', translation: "It's night.", username: 'HAGNi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11776653, text: '緑です。', translation: "It's green.", username: 'mashi', license: 'CC BY 2.0 FR'),
  ],
  '事': [
    TatoebaSentence(id: 10091423, text: '事実だよ。', translation: "That's a fact.", username: 'pabik', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8533911, text: '見事！', translation: "Great!", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11491611, text: '今日は仕事？', translation: "Are you working today?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'はい': [
    TatoebaSentence(id: 509772, text: 'はい。', translation: "Yes.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9842778, text: 'はい！', translation: "Yes!", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13080169, text: 'はい？', translation: "Pardon?", username: 'KTCXMX', license: 'CC BY 2.0 FR'),
  ],
  'ええ': [
    TatoebaSentence(id: 1166626, text: 'ええ。', translation: "Yes.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10914856, text: 'ええ、いいですよ。', translation: "Yeah, sure.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901729, text: 'ええ、好きです。', translation: "Yes, I like it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'いいえ': [
    TatoebaSentence(id: 509771, text: 'いいえ。', translation: "No.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10914816, text: 'いいえ、違います。', translation: "No, you're wrong.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10985081, text: 'いいえ、行きません。', translation: "No, I'm not going.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '行く': [
    TatoebaSentence(id: 4739, text: '行くよ。', translation: "I'm going to go.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8769317, text: '行くの？', translation: "Are you going?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11876553, text: '港に行く。', translation: "I'll go to the harbor.", username: 'cia_UnitedStatesNa13', license: 'CC BY 2.0 FR'),
  ],
  'まで': [
    TatoebaSentence(id: 14015080, text: '何時まで？', translation: "Til when?", username: 'kris514', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3080960, text: '空港まで行く。', translation: "I'm going as far as the airport.", username: 'fouafouadougou', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12976441, text: '夜まで待とう。', translation: "Let's wait until night.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '時': [
    TatoebaSentence(id: 7486060, text: 'そのときトムを知ってた？', translation: "Did you know Tom at that time?", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 212902, text: 'そのとき私は１８歳だった。', translation: "I was eighteen then.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 232621, text: 'あなたはそのとき何をしていましたか。', translation: "What were you doing then?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '時間': [
    TatoebaSentence(id: 2633830, text: '時間がない。', translation: "There's no time.", username: 'noitartsinimda', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7809264, text: '時間ある？', translation: "Are you available?", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 145662, text: '寝る時間よ。', translation: "It's time to go to bed.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '人': [
    TatoebaSentence(id: 230689, text: 'あの人誰？', translation: "Who is that man?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9851622, text: '一人かい？', translation: "Are you alone?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12022691, text: 'いい人よね？', translation: "He's a good person, isn't he?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '人間': [
    TatoebaSentence(id: 354160, text: '君は人間だ。', translation: "You're a human.", username: 'bourdu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11198447, text: '人間は２本足だ。', translation: "Humans have two legs.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1264217, text: '私は人間です。', translation: "I'm a human.", username: 'Scott', license: 'CC BY 2.0 FR'),
  ],
  '来る': [
    TatoebaSentence(id: 4561568, text: '来る？', translation: "Are you coming?", username: 'Kiraness', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12098575, text: '明日も来る？', translation: "Will you come here tomorrow, too?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13523348, text: 'バスが来る。', translation: "The bus has arrived.", username: 'YueBei', license: 'CC BY 2.0 FR'),
  ],
  'これ': [
    TatoebaSentence(id: 217564, text: 'これ何？', translation: "What is this?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8564765, text: 'これは花？', translation: "This is a flower?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13220298, text: 'これ好き？', translation: "Do you like it?", username: 'atitarev', license: 'CC BY 2.0 FR'),
  ],
  'それ': [
    TatoebaSentence(id: 3591210, text: 'それ何？', translation: "What is it?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3488459, text: 'それ本当？', translation: "Is that true?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9106549, text: 'それ好き？', translation: "Do you like it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'あれ': [
    TatoebaSentence(id: 1121259, text: 'あれ誰？', translation: "Who's that?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 229628, text: 'あれ何？', translation: "What's that?", username: 'Nihonkage', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3506637, text: 'あれを見て！', translation: "Look at that!", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  'どれ': [
    TatoebaSentence(id: 10298483, text: 'どれがいい？', translation: "Which one do you want?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3488662, text: 'どれどれ。', translation: "Let me see.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3710295, text: '私のはどれ？', translation: "Which is mine?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '今': [
    TatoebaSentence(id: 10557857, text: '今、お家？', translation: "Are you at home now?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10690223, text: '今、話せる？', translation: "Can we talk now?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10906691, text: '今何してる？', translation: "What are you doing now?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'いい': [
    TatoebaSentence(id: 9499960, text: 'いいよ。', translation: "All right.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13080161, text: 'いいね！', translation: "Neat!", username: 'KTCXMX', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4772253, text: 'いい？', translation: "Is that okay?", username: 'Ishao', license: 'CC BY 2.0 FR'),
  ],
  '所': [
    TatoebaSentence(id: 199407, text: 'どんな所がお好きですか。', translation: "What places do you enjoy?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9992496, text: '痛いところはどこ？', translation: "Where does it hurt?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2794995, text: 'どっか行きたいところある？', translation: "Is there anywhere you want to go?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'この': [
    TatoebaSentence(id: 12403574, text: 'この鍵ある？', translation: "Do you have the key?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10778218, text: 'この色はどう？', translation: "How about this color?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3551493, text: 'この音何？', translation: "What is this sound?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'その': [
    TatoebaSentence(id: 1166649, text: 'その試合見た？', translation: "Did you watch the game?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13976230, text: 'その本は白い。', translation: "The book is white.", username: 'HAGNi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10574670, text: 'その子は誰？', translation: "Who is the boy?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'あの': [
    TatoebaSentence(id: 8734235, text: 'あの人がトム？', translation: "Is that person Tom?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11021678, text: 'あの車です。', translation: "It was that car.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4292451, text: 'あの物音は何？', translation: "What is that noise?", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  'どの': [
    TatoebaSentence(id: 3697551, text: 'どの映画を観るの？', translation: "Which film are you going to see?", username: 'ii_desu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13476186, text: 'どの駅で降りるの？', translation: "Which stop are you getting off at?", username: 'ninefi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4562324, text: '東はどの方向なの？', translation: "What direction is east?", username: 'Kiraness', license: 'CC BY 2.0 FR'),
  ],
  '自分': [
    TatoebaSentence(id: 1140379, text: '自分を信じて。', translation: "Believe in yourself.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 156296, text: '自分でします。', translation: "I will do it myself.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9171558, text: '自分の部屋ある？', translation: "Do you have your own room?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'やはり': [
    TatoebaSentence(id: 1107683, text: '嘘というものは、良識ある者がついたときでも、やはり嘘なのである。', translation: "A lie, told by a sensible man, remains a lie.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2362371, text: 'いいえ、私はやはり野菜を好んで食べます。', translation: "No, I still prefer eating vegetables.", username: 'igarashi27', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 101706, text: '彼は頭がよいがやはり嫌いだ。', translation: "He's intelligent, but I still don't like him.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'する': [
    TatoebaSentence(id: 12296457, text: '幾らするの？', translation: "How much is it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13082671, text: '翻訳する。', translation: "Translate.", username: 'KTCXMX', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11001460, text: 'ご飯にする？', translation: "Do you want rice?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'やる': [
    TatoebaSentence(id: 10624199, text: 'やるよ。', translation: "I'll do it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8966980, text: '明日やるの？', translation: "Will you be doing that tomorrow?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2983000, text: '将棋でもやる？', translation: "Do you want to play shogi?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '中': [
    TatoebaSentence(id: 13537569, text: '中に入って。', translation: "Go inside.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10489229, text: '中にいるの？', translation: "Are you in there?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13080201, text: '中へ。', translation: "Go inside.", username: 'KTCXMX', license: 'CC BY 2.0 FR'),
  ],
  '外': [
    TatoebaSentence(id: 8738691, text: '外は暑い？', translation: "Is it hot outside?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11988871, text: '外は晴れてる？', translation: "Is it sunny outside?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 184872, text: '外は暗い。', translation: "It is dark outside.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
  ],
  '右': [
    TatoebaSentence(id: 5253130, text: '右に曲がって。', translation: "Turn to the right.", username: 'nihonjin', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11726744, text: '駅は右側です。', translation: "The station is on the right.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8693841, text: '彼は左右を見た。', translation: "He looked left and right.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '左': [
    TatoebaSentence(id: 5253128, text: '左に曲がって。', translation: "Turn left.", username: 'nihonjin', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10655786, text: '左利きなのよ。', translation: "I'm left-handed.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10263750, text: '左足が痛みます。', translation: "My left foot hurts.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '上': [
    TatoebaSentence(id: 10728153, text: '猫が机の上にいる。', translation: "There's a cat on the desk.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10480638, text: 'テーブルの上に置け！', translation: "Put it onto the table.", username: 'Johannes_S', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1176920, text: '家は丘の上にある。', translation: "My house is on a hill.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '下': [
    TatoebaSentence(id: 11331283, text: '猫は車の下にいる。', translation: "The cat is under the car.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 183461, text: '机の下に猫がいる。', translation: "There is a cat under the desk.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11483525, text: 'ベッドの下に、ゴキブリ！', translation: "There's a cockroach under the bed!", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ここ': [
    TatoebaSentence(id: 11294942, text: 'ここだよ。', translation: "I'm here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13511600, text: 'ここ。', translation: "Here.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3491573, text: 'ここはどこ？', translation: "Where am I?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'そこ': [
    TatoebaSentence(id: 10903329, text: 'そこにいるの？', translation: "Are you there?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8719334, text: '誰かそこにいる？', translation: "Is anyone there?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11420630, text: 'そこが肝心だ。', translation: "That's the point.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'あそこ': [
    TatoebaSentence(id: 11491621, text: 'あそこに座って。', translation: "Sit over there.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5933519, text: 'あそこを見て。', translation: "Look over there.", username: 'Sethlang', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11052427, text: '先生はあそこよ。', translation: "The teacher is over there.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'どこ': [
    TatoebaSentence(id: 5675036, text: 'どこ？', translation: "Where?", username: 'abyssalalice', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3508034, text: '家はどこ？', translation: "Where is your house?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13669575, text: 'お金はどこ？', translation: "Where's the money?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'できる': [
    TatoebaSentence(id: 4810, text: 'できるよ！', translation: "You can do it.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10075578, text: '運転できるの？', translation: "Can you drive?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11017633, text: '料理できるの？', translation: "Can you cook a meal?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '後': [
    TatoebaSentence(id: 195443, text: 'また後で。', translation: "I'll see you later.", username: 'verbum', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2581794, text: '後でやって。', translation: "Do it later.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 874000, text: '後で電話して！', translation: "Call me later.", username: 'thyc244', license: 'CC BY 2.0 FR'),
  ],
  '前': [
    TatoebaSentence(id: 3496794, text: '朝飯前だ。', translation: "It's too easy.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13511301, text: '三日前だ。', translation: "That was three days ago.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13753503, text: '食べる前に？', translation: "Before eating?", username: 'TanukiKun', license: 'CC BY 2.0 FR'),
  ],
  'また': [
    TatoebaSentence(id: 1683208, text: 'またね。', translation: "See you again.", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1130332, text: 'また来週。', translation: "See you next week!", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 195467, text: 'また雨だ。', translation: "It's raining again!", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  'まだ': [
    TatoebaSentence(id: 8845007, text: 'まだ忙しい？', translation: "Are you still busy?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10914873, text: 'まだ20よ。', translation: "She's only 20.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2355862, text: 'まだ眠いの？', translation: "Are you still sleepy?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'けれど': [
    TatoebaSentence(id: 189781, text: '雨が降っていたけれども彼女は外出した。', translation: "Though it was raining, she went out.", username: 'Blanka_Meduzo', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 104595, text: '彼は若いけれども経験がある。', translation: "He is young, but experienced.", username: 'Kaede', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 178756, text: '君と一緒に行きたいけれど文無しなんだ。', translation: "I'd like to go with you, but I'm broke.", username: 'Blanka_Meduzo', license: 'CC BY 2.0 FR'),
  ],
  'から': [
    TatoebaSentence(id: 122832, text: '日本から来ました。', translation: "I come from Japan.", username: 'Ianagisacos', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11256137, text: '暇だから寝よ。', translation: "I'm free now, so I'll just sleep.", username: 'sh5555', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4765, text: 'だから何？', translation: "So what?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'くらい': [
    TatoebaSentence(id: 5675047, text: 'どれくらい？', translation: "How long?", username: 'abyssalalice', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 200414, text: 'どのくらい広い？', translation: "How big?", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 200413, text: 'どのくらい高い？', translation: "How high is it?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'ぐらい': [
    TatoebaSentence(id: 8762347, text: '5時ぐらいだよ。', translation: "It's about five.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12296459, text: '幾らぐらいになる？', translation: "How much will it cost?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10952389, text: '今、身長どれぐらい？', translation: "How tall are you now?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ではない': [
    TatoebaSentence(id: 1240055, text: '私は教師ではない。', translation: "I am not a teacher.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2573227, text: '私は公平ではない。', translation: "I'm biased.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3507380, text: '私は内気ではない。', translation: "I'm not shy.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  'じゃない': [
    TatoebaSentence(id: 10624217, text: '嫌いじゃない。', translation: "I don't dislike it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10145729, text: '嘘じゃないよ。', translation: "That's not a lie.", username: 'h_aibe', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12271573, text: '同じじゃない。', translation: "It's not the same.", username: 'Morg', license: 'CC BY 2.0 FR'),
  ],
  '本当': [
    TatoebaSentence(id: 4751, text: '本当？', translation: "Are you sure?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 81560, text: '本当に？', translation: "Really?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 628692, text: '本当だよ！', translation: "It's true!", username: 'satosi', license: 'CC BY 2.0 FR'),
  ],
  '持つ': [
    TatoebaSentence(id: 9941412, text: '袋は僕が持つよ。', translation: "Let me get your bags for you.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9940351, text: 'それ持つよ。', translation: "Let me carry that for you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 162243, text: '車を持つ余裕はないな。', translation: "I cannot afford to keep a car.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '出る': [
    TatoebaSentence(id: 13671094, text: 'さあ、外に出るぞ。', translation: "Now, let's go outside.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5762758, text: 'いつ出る？', translation: "When are we leaving?", username: 'daifons', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2992030, text: '午後の会議、出る？', translation: "Are you going to be at this afternoon's meeting?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '入る': [
    TatoebaSentence(id: 2570479, text: '私が中に入る。', translation: "I'll go in.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6956277, text: '入る前にノックして。', translation: "Knock before entering.", username: 'Yetiowin', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12146793, text: '毎日お風呂に入るよ。', translation: "I bathe every day.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '為': [
    TatoebaSentence(id: 8663415, text: 'すごく為になります。', translation: "That's very helpful.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10528322, text: 'あなたの為にならないわ。', translation: "It's not good for you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11624781, text: '何で彼の為に働いているの？', translation: "Why are you working for him?", username: 'psykomies', license: 'CC BY 2.0 FR'),
  ],
  '思う': [
    TatoebaSentence(id: 201105, text: 'どう思う？', translation: "Now, what do you think?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 213775, text: 'そう思うかい？', translation: "Do you think so?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12056117, text: 'そう思う。', translation: "I think so.", username: 'xyz_13', license: 'CC BY 2.0 FR'),
  ],
  '考える': [
    TatoebaSentence(id: 164397, text: '考える時間をください。', translation: "Give me some time to think it over.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 14015081, text: '私は考える。', translation: "I think.", username: 'kris514', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8613573, text: 'なぜそう考えるの？', translation: "What makes you think so?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'そうですか': [
    TatoebaSentence(id: 5955917, text: 'そうですか。', translation: "I see.", username: 'tatoebane', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11029487, text: 'ああ、そうですか。', translation: "Oh, really?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12655044, text: 'そうですか、良かったです！', translation: "Alright, that's good to hear!", username: 'urro', license: 'CC BY 2.0 FR'),
  ],
  'すごい': [
    TatoebaSentence(id: 214733, text: 'すごい！', translation: "Wow!", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 214728, text: 'すごいぞ！', translation: "Terrific!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2570653, text: 'それはすごい。', translation: "That's great.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '食べる': [
    TatoebaSentence(id: 5254850, text: '食べる。', translation: "I will eat.", username: 'daichan', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12824508, text: '食べる？', translation: "Do you want to eat?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8596646, text: 'いつ食べるの？', translation: "When do we eat?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '飲む': [
    TatoebaSentence(id: 890127, text: '何か飲む？', translation: "Want a drink?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11388430, text: 'ビール飲む？', translation: "Do you want to drink some beer?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1356183, text: 'チャイを飲む。', translation: "I'll drink chai.", username: 'nonong', license: 'CC BY 2.0 FR'),
  ],
  'について': [
    TatoebaSentence(id: 894584, text: '何について？', translation: "About what?", username: 'babayoshihiko', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12020382, text: 'それについて教えて。', translation: "Tell me about it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11992633, text: '彼について何か聞いた？', translation: "Have you heard anything about him?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '作る': [
    TatoebaSentence(id: 12461975, text: '夕飯、作るね。', translation: "I'll make dinner.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 224858, text: 'コーヒー作るわ。', translation: "I will make some coffee.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11733147, text: '今日は何を作るの？', translation: "What are you cooking today?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '〜てみる': [
    TatoebaSentence(id: 10032516, text: '考えてみるよ。', translation: "I'll think about it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1503523, text: 'やってみる。', translation: "I try.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11679995, text: '調べてみるよ。', translation: "I'll look into it.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '聞く': [
    TatoebaSentence(id: 4789, text: 'なんで聞くの？', translation: "Why do you ask?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7486120, text: 'トムは聞く。', translation: "Tom listens.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 425425, text: '彼に聞くのを忘れた。', translation: "I forgot to ask him.", username: 'blay_paul', license: 'CC BY 2.0 FR'),
  ],
  '書く': [
    TatoebaSentence(id: 1572989, text: '彼は手紙を書く。', translation: "He writes a letter.", username: 'Zaghawa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9039541, text: '名前はどう書くの？', translation: "How do you spell your name?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1035914, text: 'すぐに手紙書くよ。', translation: "I will write to you soon.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'そして': [
    TatoebaSentence(id: 236125, text: '１、３そして５は奇数です。', translation: "One, three, and five are odd numbers.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 213520, text: 'そしてトニーは一番年上でした。', translation: "And Tony was the oldest.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 139428, text: 'そして、私があなた達のコーチです。', translation: "And, I'm your coach.", username: 'fcbond', license: 'CC BY 2.0 FR'),
  ],
  'ながら': [
    TatoebaSentence(id: 86786, text: '彼女は歩きながら話した。', translation: "She walked and talked.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 169232, text: '残念ながらそのようです。', translation: "I'm afraid so.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3402686, text: '彼女は涙ながらに話した。', translation: "She told her story in tears.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '場合': [
    TatoebaSentence(id: 11784938, text: '場合によるでしょ。', translation: "It depends.", username: 'Masatami', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4776, text: '最悪の場合を考えておこう。', translation: "Let's consider the worst that could happen.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 189576, text: '雨の場合私は行かない。', translation: "In case it rains, I won't go.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '使う': [
    TatoebaSentence(id: 8950341, text: '使うの簡単だよ。', translation: "It's simple to use.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 187729, text: '何に使うの？', translation: "What for?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8537255, text: 'それいつ使うの？', translation: "When do you use it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '話す': [
    TatoebaSentence(id: 10112000, text: 'ゆっくり話すね。', translation: "I'll speak slowly.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8858173, text: '話す。', translation: "Speak.", username: 'moxy', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10049592, text: 'アイヌ語を話すの？', translation: "Do you speak Ainu?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '日本': [
    TatoebaSentence(id: 122413, text: '日本は島国だ。', translation: "Japan is an island country.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13753497, text: '日本へようこそ！', translation: "Welcome to Japan!", username: 'TanukiKun', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2412133, text: '日本の方ですか？', translation: "Are you Japanese?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'イギリス': [
    TatoebaSentence(id: 9106981, text: 'イギリスは島です。', translation: "Britain is an island.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 229265, text: 'イギリスから来ました。', translation: "I come from England.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1682326, text: 'ロンドンはイギリスの首都。', translation: "London is the capital of the United Kingdom.", username: 'Zaghawa', license: 'CC BY 2.0 FR'),
  ],
  '国': [
    TatoebaSentence(id: 13187353, text: '台湾は国です。', translation: "Taiwan is a country.", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1483651, text: '中国が好きだ。', translation: "I like China.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11263451, text: '山国です。', translation: "It's a very mountainous country.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '子供': [
    TatoebaSentence(id: 2040863, text: '子供が欲しい？', translation: "Do you want children?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1484854, text: '子供がいますか。', translation: "Do you have children?", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 168732, text: '子供たちは元気？', translation: "How are the kids?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '知る': [
    TatoebaSentence(id: 11512359, text: '知ってる？', translation: "Do you know?", username: 'megamanenm', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13344749, text: '知ってるよ。', translation: "I know.", username: 'cost_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8026854, text: 'この曲知ってる？', translation: "Do you know this tune?", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  'みたい': [
    TatoebaSentence(id: 11576335, text: 'そうみたい。', translation: "It seems so.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 628655, text: '雪みたい。', translation: "It looks like snow.", username: 'kebukebu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12698544, text: '別人みたい。', translation: "You look like a completely different person.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '同じ': [
    TatoebaSentence(id: 12271573, text: '同じじゃない。', translation: "It's not the same.", username: 'Morg', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13080209, text: '同じく。', translation: "Same here.", username: 'KTCXMX', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 774830, text: '同じ意見です。', translation: "I agree.", username: 'marloncori', license: 'CC BY 2.0 FR'),
  ],
  'とても': [
    TatoebaSentence(id: 200671, text: 'とてもいいよ。', translation: "It's very good.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 347140, text: 'とても疲れた。', translation: "I'm exhausted.", username: 'zhouj1955', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13537670, text: 'とても楽しい。', translation: "It is very fun.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
  ],
  '少し': [
    TatoebaSentence(id: 2226724, text: '少し忙しい。', translation: "I'm a little busy.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10608937, text: '少し待ってて。', translation: "Wait a moment.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 146779, text: '少し疲れた。', translation: "I'm a little tired.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '一番': [
    TatoebaSentence(id: 2562498, text: '私が一番。', translation: "I'm first.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11138359, text: '夏が一番好き。', translation: "I like summer best.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10155826, text: '我が家が一番！', translation: "There is no place like home.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'まず': [
    TatoebaSentence(id: 10650598, text: 'まずは基本から。', translation: "Start with the basics.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9106843, text: 'まずは食べよう。', translation: "Let's eat first.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6850086, text: 'まずははじめの一歩から。', translation: "First things first.", username: 'Sonata', license: 'CC BY 2.0 FR'),
  ],
  '必要': [
    TatoebaSentence(id: 178881, text: '君が必要だ。', translation: "I need you.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9839309, text: 'お金が必要だ。', translation: "I need money.", username: 'MsFixer', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11776431, text: '助言が必要だ。', translation: "I need advice.", username: 'mashi', license: 'CC BY 2.0 FR'),
  ],
  '仕事': [
    TatoebaSentence(id: 4751202, text: 'どう、仕事は？', translation: "How's work?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8613815, text: '仕事に戻れ！', translation: "Get back to work!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11171521, text: '仕事、やだ。', translation: "I hate work.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '好き': [
    TatoebaSentence(id: 3697521, text: '好きです。', translation: "I like you.", username: 'ii_desu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1661532, text: '大好き。', translation: "I love you.", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10624640, text: '子供好き？', translation: "Do you like kids?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '嫌い': [
    TatoebaSentence(id: 8874675, text: '猫が嫌い。', translation: "I hate cats.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4862, text: '化学が嫌いだ。', translation: "I hate chemistry.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7486197, text: '月曜日が嫌い。', translation: "I hate Mondays.", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  'あまり': [
    TatoebaSentence(id: 5157, text: 'あまり見えない。', translation: "I see it rarely.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 230333, text: 'あまり希望がない。', translation: "There is not much hope.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7930650, text: 'あまり旅行しない。', translation: "I don't travel very much.", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  'かもしれない': [
    TatoebaSentence(id: 101932, text: '彼は天才かもしれない。', translation: "He may be a genius.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 189732, text: '雨が降るかもしれない。', translation: "It may rain.", username: 'qahwa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10995283, text: '気のせいかもしれない。', translation: "Maybe it's just my imagination.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '次': [
    TatoebaSentence(id: 3491565, text: '次は誰？', translation: "Who's next?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12777920, text: '次の予定は？', translation: "What's next?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4215915, text: '次はない。', translation: "There won't be a next time.", username: 'megamanenm', license: 'CC BY 2.0 FR'),
  ],
  '彼': [
    TatoebaSentence(id: 102315, text: '彼は誰？', translation: "Who is he?", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13224632, text: '彼氏いるの？', translation: "Do you have a boyfriend?", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2125129, text: '彼の名前は？', translation: "What is his name?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '彼女': [
    TatoebaSentence(id: 1622575, text: '彼女は元気？', translation: "Is she healthy?", username: 'Bah_Dure', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13224678, text: '彼女いる？', translation: "Do you have a girlfriend?", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11776723, text: '彼女が欲しい。', translation: "I want a girlfriend.", username: 'mashi', license: 'CC BY 2.0 FR'),
  ],
  '誰': [
    TatoebaSentence(id: 638666, text: '誰？', translation: "Who are you?", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1771926, text: '君は誰？', translation: "Who are you?", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7551822, text: '誰が来た？', translation: "Who came?", username: 'Kitsuneko', license: 'CC BY 2.0 FR'),
  ],
  '例えば': [
    TatoebaSentence(id: 77714, text: '例えば、これは一本のペンです。', translation: "For example, this is a pen.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 337412, text: '例えば、英語が好きですか。', translation: "For example, do you like English?", username: 'Swift', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12148293, text: '「何かしろよ！」「例えば？」', translation: '"Do something!" "Like what?"', username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '入れる': [
    TatoebaSentence(id: 9687105, text: '氷は入れる？', translation: "Would you like ice?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1614431, text: 'コーヒーに砂糖は入れる？', translation: "Do you take sugar in your coffee?", username: 'Meow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11836921, text: '紅茶にミルクを入れる？', translation: "Do you put milk in your tea?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '買う': [
    TatoebaSentence(id: 9119413, text: 'それ買うよ。', translation: "I'll buy it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 778264, text: '辞書を買うんですか？', translation: "Are you going to buy a dictionary?", username: 'kenken', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13617668, text: 'コンビニで何を買うの？', translation: "What are you going to buy at the supermarket?", username: 'ninefi', license: 'CC BY 2.0 FR'),
  ],
  '高い': [
    TatoebaSentence(id: 202087, text: 'でも高いよ。', translation: "It's expensive though.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13130047, text: '高いですね。', translation: "It's too expensive.", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 121666, text: '波が高い。', translation: "The waves are high.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '安い': [
    TatoebaSentence(id: 8576543, text: '安いね。', translation: "That's cheap, isn't it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1944403, text: 'これは安いです。', translation: "This is cheap.", username: 'jayjaying', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 171645, text: '今日は魚が安い。', translation: "Fish is cheap today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '払う': [
    TatoebaSentence(id: 2139734, text: '今日払うよ。', translation: "I'll pay today.", username: 'Blanka_Meduzo', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8694662, text: 'あなたが払うつもり？', translation: "Are you going to pay?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11674951, text: '今日は、私が払うわ。', translation: "Today I'm paying.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '始める': [
    TatoebaSentence(id: 1177286, text: '彼らは始めるところです。', translation: "They are about to start.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 945909, text: '新たに始める。', translation: "I will begin anew.", username: 'oxioxigen', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1228877, text: '始める準備はできている。', translation: "I'm all set to start.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '終わる': [
    TatoebaSentence(id: 8727067, text: 'もうすぐ終わる？', translation: "Are you almost finished?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 228649, text: 'いつ終わるの？', translation: "When does it end?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11358720, text: '三月が終わる。', translation: "March is over.", username: 'cia_UnitedStatesNa13', license: 'CC BY 2.0 FR'),
  ],
  '体': [
    TatoebaSentence(id: 226181, text: '体中が痛い。', translation: "I ache all over.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 138013, text: '体に悪いよ。', translation: "It's not healthy for you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10159575, text: '体調が悪いの？', translation: "Are you sick?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '目': [
    TatoebaSentence(id: 79990, text: '目が痛い。', translation: "My eyes hurt.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1080897, text: '目を開けて。', translation: "Open your eyes.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9312317, text: '目が悪いの？', translation: "Are your eyes bad?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '手': [
    TatoebaSentence(id: 10153664, text: '手を広げて。', translation: "Open your hand!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8764392, text: '手を見せて。', translation: "Show me your hands.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12882304, text: '手を洗おうよ。', translation: "Let's wash our hands.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '足': [
    TatoebaSentence(id: 8785075, text: '足が冷えたの？', translation: "Are your feet cold?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 139876, text: '足が痛い。', translation: "I have sore feet.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10588114, text: '足が寒い。', translation: "My feet are cold.", username: 'Sonata', license: 'CC BY 2.0 FR'),
  ],
  '腕': [
    TatoebaSentence(id: 11667981, text: '腕が痛いんだ。', translation: "My arm hurts.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8649674, text: '腕相撲しない？', translation: "You wanna arm wrestle?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 77121, text: '腕が痛む。', translation: "I have an ache in my arm.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '頭': [
    TatoebaSentence(id: 123871, text: '頭が痛い。', translation: "I have a headache.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6860386, text: '頭を使え。', translation: "Use your head.", username: 'tsukimori', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1325382, text: '頭を冷やせ！', translation: "Calm down.", username: 'Scott', license: 'CC BY 2.0 FR'),
  ],
  '言葉': [
    TatoebaSentence(id: 10195029, text: 'この言葉いいね。', translation: "I like this word.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12577570, text: '言葉は大切ね。', translation: "Language is important.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10045029, text: '言葉を失った。', translation: "I was at a loss for words.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '違う': [
    TatoebaSentence(id: 1251862, text: '違う！', translation: "No!", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5067275, text: '違う。', translation: "That's wrong.", username: '999yudai', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8580425, text: '何が違うの？', translation: "What's the difference?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '意味': [
    TatoebaSentence(id: 2492791, text: 'どういう意味？', translation: "What do you mean?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11340563, text: '意味がわからない。', translation: "I don't understand what it means.", username: 'cia_UnitedStatesNa13', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10294446, text: 'それは無意味だよ。', translation: "That's pointless.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '家': [
    TatoebaSentence(id: 4864642, text: '家にいる。', translation: "I am at home.", username: 'jarbv', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3508034, text: '家はどこ？', translation: "Where is your house?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8699812, text: '家に帰るの？', translation: "Are you going home?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '部屋': [
    TatoebaSentence(id: 760552, text: '部屋が暑い。', translation: "The room is hot.", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9183307, text: '小さな部屋ね。', translation: "It's a small room.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13507688, text: '私の部屋です。', translation: "This is my room.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '居間': [
    TatoebaSentence(id: 9192461, text: '居間の電気は消したの？', translation: "Did you switch the light off in the living room?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 187047, text: '家の居間は日当たりが良いよ。', translation: "Our living room is sunny.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10655918, text: '本は居間の机の上に置いたよ。', translation: "I put the book on the table in the living room.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '床': [
    TatoebaSentence(id: 11391181, text: '床に置いて。', translation: "Put it on the floor.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8615894, text: '床は冷たい。', translation: "The floor is cold.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 104064, text: '彼は床に倒れた。', translation: "He fell down on the floor.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '壁': [
    TatoebaSentence(id: 83453, text: '壁の絵を見て。', translation: "Look at the picture on the wall.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 83468, text: '壁にもたれるな。', translation: "Don't lean against the wall.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11524863, text: '壁には蜘蛛がいる。', translation: "There's a spider on the wall.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '猫': [
    TatoebaSentence(id: 8874675, text: '猫が嫌い。', translation: "I hate cats.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6828218, text: '猫が寝る。', translation: "A cat sleeps.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10603327, text: '猫は賢いよ。', translation: "Cats are smart.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '犬': [
    TatoebaSentence(id: 778207, text: '犬を見た。', translation: "I saw a dog.", username: 'kenken', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 553874, text: '犬は賢い。', translation: "Dogs are smart.", username: 'Namikaze', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8733220, text: '犬が怖いの？', translation: "Are you afraid of dogs?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '馬': [
    TatoebaSentence(id: 2445792, text: '私は馬が好きです。', translation: "I like horses.", username: 'x_meta', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10246225, text: '馬に乗れるの？', translation: "Can you ride a horse?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8762329, text: '馬がトムを噛んだ。', translation: "A horse bit Tom.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '男': [
    TatoebaSentence(id: 155143, text: '私は男だ。', translation: "I am a man.", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3488326, text: '僕、男だよ。', translation: "I am a boy.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3468493, text: '男が三人いた。', translation: "There were three men.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '女': [
    TatoebaSentence(id: 764118, text: '私は女だ。', translation: "I am a woman.", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13756243, text: '女です。', translation: "I'm a woman.", username: 'TanukiKun', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10198336, text: '女兄弟はいる？', translation: "Do you have any sisters?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '形': [
    TatoebaSentence(id: 77791, text: '林檎の形は丸い。', translation: "An apple is round in shape.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2243170, text: 'この文は現在形です。', translation: "This sentence is in the present tense.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 225670, text: 'クッキーはどれも星の形をしている。', translation: "The cookies are all in the form of stars.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '間': [
    TatoebaSentence(id: 121948, text: '猫は枝の間に隠れた。', translation: "The cat hid among the branches.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 78088, text: '両者の間に関係はない。', translation: "There is no connection between them.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 147601, text: '春は冬と夏の間に訪れる。', translation: "Spring comes between winter and summer.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '最初': [
    TatoebaSentence(id: 170498, text: '最初から始めよう。', translation: "Let's begin at the beginning.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10470732, text: '最初にこれをして。', translation: "Do this first.", username: 'h_aibe', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2125075, text: '私が最初に行きます。', translation: "I'll go first.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '最後': [
    TatoebaSentence(id: 1678497, text: '最後のチャンス！', translation: "Last call!", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10910928, text: 'これが最後だ。', translation: "This is the last one.", username: 'SomeHungryBois', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11582485, text: '最後まで闘います。', translation: "I will fight until the end.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '最高': [
    TatoebaSentence(id: 13537077, text: '最高だ。', translation: "I'm the best.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11256134, text: '最高！', translation: "Incredible!", username: 'sh5555', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 170540, text: '最高の気分だ。', translation: "I'm on top of the world.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '最低': [
    TatoebaSentence(id: 170386, text: '最低！', translation: "You're disgusting!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13065971, text: '最低でも1時間はかかる。', translation: "It'll take at least an hour.", username: 'Gardenia', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 171910, text: '今日の最低気温は３℃だった。', translation: "Today's minimum temperature was 3 °C.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '感じる': [
    TatoebaSentence(id: 236863, text: '私は幸せに感じる。', translation: "I feel happy.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 188407, text: '何か感じる。', translation: "I feel something.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11340503, text: '距離を感じる。', translation: "I feel the distance.", username: 'cia_UnitedStatesNa13', license: 'CC BY 2.0 FR'),
  ],
  '気持ち': [
    TatoebaSentence(id: 3495029, text: '気持ちが悪い。', translation: "I feel awful.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10497503, text: 'これ、気持ちいい！', translation: "This feels good.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10913712, text: '気持ちは分かる。', translation: "I understand how you feel.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '大きい': [
    TatoebaSentence(id: 13063899, text: '大きいね。', translation: "It's big.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 104507, text: '彼は手が大きい。', translation: "He has big hands.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2684241, text: 'その本は大きい。', translation: "The book is big.", username: 'cogas', license: 'CC BY 2.0 FR'),
  ],
  '小さい': [
    TatoebaSentence(id: 4811495, text: '小さい！', translation: "So small!", username: 'Deagger', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3477255, text: 'この本は小さい。', translation: "This book is small.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11325452, text: '手は小さいんだ。', translation: "I have small hands.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '遠い': [
    TatoebaSentence(id: 5055, text: 'ここから遠いの？', translation: "Is it far from here?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10466997, text: '町までは遠いよ。', translation: "It's a long way to town.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2689891, text: '遠い地平線を見て！', translation: "Look at the distant horizon!", username: 'Hikaru', license: 'CC BY 2.0 FR'),
  ],
  '近い': [
    TatoebaSentence(id: 85333, text: '病院はここから近い。', translation: "The hospital is near here.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 163973, text: '私の家は駅から近い。', translation: "My house is near the station.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3137754, text: '近いうちに話そう。', translation: "Let's talk soon.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '最近': [
    TatoebaSentence(id: 373204, text: '最近どうだ？', translation: "How have you been recently?", username: 'blay_paul', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10089952, text: '最近、映画見た？', translation: "Have you seen any movies lately?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11639999, text: '最近、忙しくて。', translation: "I have been busy lately.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '特に': [
    TatoebaSentence(id: 2073821, text: '特にアレルギーはありません。', translation: "I don't have any allergies.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 172252, text: '今朝は特に寒い。', translation: "It is especially cold this morning.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 123469, text: '特に痛みはありません。', translation: "I have no pain in particular.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '友達': [
    TatoebaSentence(id: 8603625, text: '友達が欲しい。', translation: "I want a friend.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6576395, text: '友達にならない？', translation: "Want to be my friend?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13756204, text: '友達がいない。', translation: "I don't have any friends.", username: 'TanukiKun', license: 'CC BY 2.0 FR'),
  ],
  '今日': [
    TatoebaSentence(id: 8823015, text: '今日は何する？', translation: "What are you going to do today?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8749239, text: '今日って暇？', translation: "Are you free today?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12476815, text: '今日も雨だ。', translation: "It's raining again today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '昨日': [
    TatoebaSentence(id: 8729229, text: '昨日は暑かった？', translation: "Was it hot yesterday?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12484478, text: '昨日、泳いだ？', translation: "Did you swim yesterday?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12418821, text: '昨日の夜見たよ。', translation: "I saw it last night.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '明日': [
    TatoebaSentence(id: 10689039, text: '明日何するの？', translation: "What are you doing tomorrow?", username: 'DJ_Saidez', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10287633, text: '明日行くよ。', translation: "I'm going tomorrow.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4593736, text: '明日暇？', translation: "Are you free tomorrow?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '明後日': [
    TatoebaSentence(id: 11171012, text: '明後日は火曜日です。', translation: "The day after tomorrow is Tuesday.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2366080, text: 'また明後日。', translation: "See you in two days.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10515260, text: '明後日には出発します。', translation: "We're leaving the day after tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '朝': [
    TatoebaSentence(id: 8719697, text: 'もう朝なの？', translation: "Is it morning already?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10682395, text: '私は朝型です。', translation: "I'm a morning person.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9755625, text: '朝の８時です。', translation: "It's 8:00 am.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '昼': [
    TatoebaSentence(id: 226829, text: 'お昼ですよ。', translation: "Lunch is on.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10741316, text: '昼寝したら？', translation: "Why don't you take a nap?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11156780, text: '昼からです。', translation: "I'm starting at noon.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '夜': [
    TatoebaSentence(id: 79755, text: '夜だった。', translation: "It was night.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12098501, text: '夜になる。', translation: "Night's coming.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1465210, text: '今夜会える？', translation: "Can you meet tonight?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'おはようございます': [
    TatoebaSentence(id: 335372, text: 'おはようございます。', translation: "Good morning!", username: 'Aurix', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10726826, text: '先生、おはようございます！', translation: "Good morning, doctor!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 778267, text: '皆様、おはようございます。', translation: "Good morning, everybody.", username: 'kenken', license: 'CC BY 2.0 FR'),
  ],
  'こんにちは': [
    TatoebaSentence(id: 3480287, text: 'こんにちは！', translation: "Hello!", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9107204, text: '皆さんこんにちは。', translation: "Hello everyone.", username: 'tontonton', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8736613, text: 'こんにちは、リサ！', translation: "Hello, Lisa.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'こんばんは': [
    TatoebaSentence(id: 426900, text: 'こんばんは。', translation: "Good evening.", username: 'qahwa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9453923, text: 'こんばんは。ご機嫌いかが？', translation: "Good evening, how are you?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 171224, text: '今晩は予定がある？', translation: "What are you doing tonight?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'さようなら': [
    TatoebaSentence(id: 640569, text: 'さようなら。', translation: "See you again.", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 426889, text: 'さようなら！', translation: "Good-bye!", username: 'qahwa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 216704, text: 'さようなら。また会いましょう。', translation: "I'll be seeing you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'またね': [
    TatoebaSentence(id: 1683208, text: 'またね。', translation: "See you again.", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 360557, text: 'またね！', translation: "I'll see you later.", username: 'Kazune', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 941192, text: 'じゃあ、またね。', translation: "I'll see you later.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '結局': [
    TatoebaSentence(id: 107802, text: '彼は結局正しかった。', translation: "He was right after all.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 90296, text: '彼女は結局来なかった。', translation: "She didn't come after all.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 157333, text: '私は結局失敗した。', translation: "I failed after all.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '生活': [
    TatoebaSentence(id: 103762, text: '彼は新生活を始めた。', translation: "He started a new life.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3244928, text: 'ドイツでの生活はどう？', translation: "How's life in Germany?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 220917, text: 'この生活に疲れた。', translation: "I'm tired of living this life.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '車': [
    TatoebaSentence(id: 11876554, text: '車に乗る。', translation: "I'll take a car.", username: 'cia_UnitedStatesNa13', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6828192, text: '車がある。', translation: "I have a car.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4769892, text: 'この車誰の？', translation: "Whose car is this?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '電気': [
    TatoebaSentence(id: 8586482, text: '電気消して。', translation: "Put out the light.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9637316, text: '電気つけて。', translation: "Turn on the lights.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 124858, text: '電気がつきません。', translation: "The light doesn't work.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '電車': [
    TatoebaSentence(id: 9032518, text: '電車来たよ。', translation: "Here comes the train.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7453564, text: '電車が好きだ。', translation: "I like trains.", username: 'Kitsuneko', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 124815, text: '電車で行こう。', translation: "Let's take a train.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '乗る': [
    TatoebaSentence(id: 200266, text: 'どの電車に乗るんですか？', translation: "Which train are you catching?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 77550, text: '列車に乗るのが好きだ。', translation: "I like to ride on trains.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 189946, text: '飲んだら乗るな。', translation: "Don't drink and drive.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '悪い': [
    TatoebaSentence(id: 3841989, text: '悪いですか？', translation: "Is it bad?", username: 'Youmu970', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3491574, text: '悪い子ね！', translation: "You're bad.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8612417, text: '気分が悪いの？', translation: "Are you not feeling well?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '心': [
    TatoebaSentence(id: 11741484, text: '心を開けよ。', translation: "Open your hearts.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10040048, text: '心が痛い。', translation: "My heart hurts.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3507389, text: '心配だわ。', translation: "I'm worried.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '会社': [
    TatoebaSentence(id: 157955, text: '私は会社員です。', translation: "I am an office worker.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3594910, text: 'トムは会社を辞めた。', translation: "Tom quit the company.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10193046, text: '彼は会社の社長です。', translation: "He is the company president.", username: 'terrywallwork', license: 'CC BY 2.0 FR'),
  ],
  '置く': [
    TatoebaSentence(id: 219776, text: 'この本どこに置くの？', translation: "Where does this book go?", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11052190, text: 'そこに椅子を置くんじゃない。', translation: "Don't put the chair there.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10989471, text: 'ここにモノを置くな。', translation: "Don't put things here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '残る': [
    TatoebaSentence(id: 9853716, text: '強いものだけが生き残る。', translation: "Only the strong survive.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8920182, text: '君と一緒にここに残るよ。', translation: "I'll stay here with you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10470719, text: 'ここに残るって決めたんだ。', translation: "I've decided to stay here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '教える': [
    TatoebaSentence(id: 158299, text: '私は英語を教える。', translation: "I teach English.", username: 'pierrephi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10606935, text: 'やり方を教えるね。', translation: "I'll show you how to do it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 14015083, text: '私は教える。', translation: "I teach.", username: 'kris514', license: 'CC BY 2.0 FR'),
  ],
  '学校': [
    TatoebaSentence(id: 2758013, text: '学校へ行く。', translation: "I'm going to school.", username: 'Balamax', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2446172, text: '学校は好き？', translation: "Do you like school?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1168139, text: '君の学校はどこ？', translation: "Where's your school?", username: 'riccioberto', license: 'CC BY 2.0 FR'),
  ],
  '大学': [
    TatoebaSentence(id: 137609, text: '大学生です。', translation: "I am a university student.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9796715, text: '大学に行ってるの？', translation: "Do you go to college?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11457757, text: '大学2年生です。', translation: "I'm a sophomore.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '学生': [
    TatoebaSentence(id: 10756859, text: '学生です。', translation: "I am a student.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12954890, text: '学生なの？', translation: "Are you a student?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13172381, text: '君は学生？', translation: "Are you a student?", username: 'atitarev', license: 'CC BY 2.0 FR'),
  ],
  '先生': [
    TatoebaSentence(id: 155469, text: '私は先生です。', translation: "I'm a teacher.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10624307, text: '先生なの？', translation: "Are you a teacher?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901727, text: '父は先生です。', translation: "My father is a teacher.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '場所': [
    TatoebaSentence(id: 10247035, text: 'この場所が好きだ！', translation: "I love this place!", username: 'h_aibe', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10032279, text: '素敵な場所だよね？', translation: "This is a nice place, don't you think?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10906700, text: '場所教えて。', translation: "Tell me where it is.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '店': [
    TatoebaSentence(id: 12073049, text: '店は開いている。', translation: "The store is open.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5067234, text: '誰が店に行くの？', translation: "Who is going to the store?", username: '999yudai', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8607027, text: 'そのお店はどこ？', translation: "Where is the store?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '楽しい': [
    TatoebaSentence(id: 9007630, text: '凄く楽しいです。', translation: "It's a lot of fun.", username: 'Kenbi93', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 78158, text: '旅行は楽しい。', translation: "It's fun to travel.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 143986, text: '人生は楽しい。', translation: "Life is sweet.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'つまらない': [
    TatoebaSentence(id: 8689056, text: 'つまらないの？', translation: "Are you bored?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1046268, text: '家にいるのはつまらない。', translation: "Staying home isn't fun.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2210270, text: 'この小説はつまらない。', translation: "This novel is boring.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '今度': [
    TatoebaSentence(id: 217496, text: '今度は誰の番だい？', translation: "Whose turn is it next?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9483347, text: '今度ラーメン行こう。', translation: "Let's go out for some ramen sometime soon.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 195544, text: 'また、今度な！', translation: "Maybe next time!", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '普通': [
    TatoebaSentence(id: 8693575, text: 'これは普通のこと？', translation: "Is this normal?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11508303, text: '普通だよ。', translation: "It's normal.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3366933, text: '普通に呼吸して。', translation: "Breathe normally.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '強い': [
    TatoebaSentence(id: 108389, text: '彼は強い。', translation: "He is powerful.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3488530, text: '風が強いな。', translation: "It's windy.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12056091, text: 'アメリカは強い。', translation: "America is strong.", username: 'xyz_13', license: 'CC BY 2.0 FR'),
  ],
  '弱い': [
    TatoebaSentence(id: 5568080, text: '君は弱いな。', translation: "You are weak.", username: 'Hekima', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2628414, text: 'トムは弱い。', translation: "Tom's weak.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 105477, text: '彼は視力が弱い。', translation: "He has poor eyesight.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '水': [
    TatoebaSentence(id: 143813, text: '水が欲しい。', translation: "I want some water.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9180994, text: '水をくれ！', translation: "Give me water!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8796822, text: '水は冷たい？', translation: "Is the water cold?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '土': [
    TatoebaSentence(id: 4562327, text: '土は何色なの？', translation: "What color is the dirt?", username: 'Kiraness', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 124478, text: '土曜日だよ。', translation: "It is Saturday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11906459, text: '土日は休みよ。', translation: "I'm off on weekends.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '火': [
    TatoebaSentence(id: 186723, text: '火を消せ。', translation: "Put out the fire.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4521742, text: '火が必要だ。', translation: "We need fire.", username: 'atomsk', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11332873, text: '火元はなに？', translation: "What started the fire?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '世界': [
    TatoebaSentence(id: 11256098, text: '世界は広い。', translation: "The world is vast.", username: 'sh5555', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 775200, text: 'この世界は難しい。', translation: "This world is difficult.", username: 'klismangok', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901691, text: '一つの世界である。', translation: "There is one world.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '早い': [
    TatoebaSentence(id: 10625543, text: '朝は早いですよ。', translation: "I'm an early riser.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9112549, text: '早いじゃん。', translation: "You are early.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11571060, text: '早い方がいい。', translation: "The earlier the better.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '速い': [
    TatoebaSentence(id: 102694, text: '彼は足が速い。', translation: "He is a fast runner.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11928921, text: '車は速いな。', translation: "The car is fast.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 187814, text: '何て速いんだろう。', translation: "So quick!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '遅い': [
    TatoebaSentence(id: 7577231, text: 'トムは遅い。', translation: "Tom's late.", username: 'Kisu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 228551, text: 'いまさら遅いよ。', translation: "It's too late now.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2328282, text: '私は歩くのが遅い。', translation: "I walk slowly.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
  ],
  '会う': [
    TatoebaSentence(id: 8002482, text: '僕らは２時半に会う。', translation: "We'll meet at 2:30.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12698869, text: '今日、会うよ。', translation: "I'll see him today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 152605, text: '私は明日彼に会う。', translation: "I'll be seeing him tomorrow.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '家族': [
    TatoebaSentence(id: 12022265, text: '私たちは家族です。', translation: "We are a family.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6135294, text: '家族は大切だ。', translation: "Family is important.", username: 'Melvin05', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 186941, text: '家族は４人です。', translation: "We are a family of four.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'お母さん': [
    TatoebaSentence(id: 226610, text: 'お母さんはどこ？', translation: "Where is mother?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1489998, text: 'お母さんが大好き。', translation: "I love my mother.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11858185, text: 'お母さんが正しい。', translation: "My mother is right.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'お父さん': [
    TatoebaSentence(id: 10144909, text: 'お父さんはどこ？', translation: "Where is your father?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5185665, text: 'お父さん、大好き！', translation: "Daddy, I love you!", username: 'aoi0913', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1356165, text: 'お父さんは医者ですか？', translation: "Is your father a doctor?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '多分': [
    TatoebaSentence(id: 2626304, text: 'トムは多分正しい。', translation: "Tom is probably right.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8823041, text: '多分そうだよ。', translation: "Maybe that's right.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2626305, text: 'トムは多分大丈夫。', translation: "Tom is probably OK.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
  ],
  '長い': [
    TatoebaSentence(id: 9107203, text: '長い道のりだ。', translation: "The road is long.", username: 'tontonton', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 146304, text: '象は鼻が長い。', translation: "An elephant has a long nose.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9067775, text: '夏は日が長い。', translation: "The days are long in the summer.", username: 'doemaar14', license: 'CC BY 2.0 FR'),
  ],
  '短い': [
    TatoebaSentence(id: 3496836, text: '人生は短い。', translation: "Life is short.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 94068, text: '彼女の髪は短い。', translation: "She has short hair.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2694272, text: 'トムは気が短い。', translation: "Tom has a short temper.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '本': [
    TatoebaSentence(id: 11367248, text: '本だ。', translation: "It is a book.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 219639, text: 'この本は古い。', translation: "This book is old.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1944380, text: 'この本は私のです。', translation: "This book is mine.", username: 'jayjaying', license: 'CC BY 2.0 FR'),
  ],
  'きれい': [
    TatoebaSentence(id: 10450147, text: 'きれいでしょ？', translation: "It's pretty, isn't it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13231307, text: 'きれいですね。', translation: "She is beautiful.", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12593361, text: '手はきれいよ。', translation: "My hands are clean.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '美味しい': [
    TatoebaSentence(id: 12890061, text: '美味しいです。', translation: "It's delicious!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11367280, text: '美味しい！', translation: "Yummy!", username: 'purehearted', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8635928, text: '本当に美味しい。', translation: "It tastes really yummy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'うまい': [
    TatoebaSentence(id: 13080190, text: 'うまい！', translation: "Yummy!", username: 'KTCXMX', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12056104, text: 'ご飯はうまい。', translation: "The rice is delicious.", username: 'xyz_13', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 77955, text: '料理うまいね。', translation: "You are a good cook, aren't you?", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '可愛い': [
    TatoebaSentence(id: 10352638, text: '可愛いよ。', translation: "You're cute.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9740669, text: '猫って可愛い。', translation: "Cats are cute.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8445951, text: '彼女は可愛い。', translation: "She's a cutie.", username: 'Shigure', license: 'CC BY 2.0 FR'),
  ],
  '立つ': [
    TatoebaSentence(id: 78276, text: '立って下さい。', translation: "Stand up, please.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11529830, text: '端っこに立ってろ！', translation: "Stand in the corner!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 110799, text: '彼はまだ立っている。', translation: "He is still standing.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '座る': [
    TatoebaSentence(id: 170840, text: '座るいすがないな。', translation: "There's no chair to sit upon.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4659104, text: '猫が机の上に座る。', translation: "The cat is sitting on top of the table.", username: 'anhgosho', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10138755, text: '座るとこ探そうよ。', translation: "Let's find something to sit on.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '毎日': [
    TatoebaSentence(id: 9392399, text: '毎日、日は昇る。', translation: "The sun rises every day.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8645486, text: '毎日電話するよ。', translation: "I'm going to call you every day.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5289421, text: '毎日、走ります。', translation: "I run every day.", username: 'SnowyDoll', license: 'CC BY 2.0 FR'),
  ],
  '毎年': [
    TatoebaSentence(id: 10531344, text: '毎年同じだよ。', translation: "It's the same every year.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 81243, text: '毎年行きます。', translation: "I go every year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99772, text: '彼は毎年海外へ行く。', translation: "He goes abroad every year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '覚える': [
    TatoebaSentence(id: 12288648, text: '僕は覚えるのが遅いんだ。', translation: "I'm a slow learner.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11199179, text: '覚えるの、簡単よ。', translation: "It's easy to learn.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8751995, text: '人の顔覚えるのって得意？', translation: "Are you good at remembering faces?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '勉強': [
    TatoebaSentence(id: 4589949, text: '勉強する。', translation: "I will study.", username: 'LeeSooHa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9495578, text: '勉強してるの？', translation: "Are you studying?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13142105, text: '一緒に勉強しよう！', translation: "Let's study together!", username: 'atitarev', license: 'CC BY 2.0 FR'),
  ],
  '説明': [
    TatoebaSentence(id: 4216062, text: '説明してくれる？', translation: "Can you explain it to me?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5762768, text: '説明させて。', translation: "Let me explain.", username: 'daifons', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11682798, text: 'その説明は簡単よ。', translation: "The explanation is simple.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '質問': [
    TatoebaSentence(id: 149535, text: '質問があります。', translation: "I have a question.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2278888, text: '質問はありますか？', translation: "Do you have any questions?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12817015, text: 'いい質問ですね。', translation: "That's a good question.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '大丈夫': [
    TatoebaSentence(id: 997206, text: '大丈夫？', translation: "You all right?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 376403, text: '大丈夫だ。', translation: "I am okay.", username: 'saeb', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3496672, text: '私は大丈夫。', translation: "I'm all right.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '面白い': [
    TatoebaSentence(id: 4913841, text: '面白い。', translation: "Interesting.", username: 'Rainnye', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 80191, text: '面白いですね。', translation: "It's interesting.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12146334, text: '犬は面白い。', translation: "Dogs are funny.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '大事': [
    TatoebaSentence(id: 3363062, text: '大事なものか？', translation: "Is it important?", username: 'dbahasa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 83291, text: '勉強も遊びも大事だ。', translation: "Both work and play are important.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10899517, text: 'あいさつは大事だよ。', translation: "Greetings are important.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],

  // JLPT N5 Vocabulary (see sets_data.dart) - the words below that aren't
  // already covered above by Essential Vocabulary's own overlapping words.
  '電話': [
    TatoebaSentence(id: 3480329, text: '電話してね。', translation: "Call me.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 124722, text: '電話です。', translation: "You are wanted on the phone.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8576496, text: '彼に電話した？', translation: "Did you telephone him?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '写真': [
    TatoebaSentence(id: 10630203, text: '写真は見た？', translation: "Did you see the picture?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2231002, text: '写真見せて。', translation: "Show me the photo.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9638023, text: '昔の写真だよ。', translation: "It's an old picture.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '全部': [
    TatoebaSentence(id: 3507409, text: 'それで全部？', translation: "Is that all?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10129855, text: '全部読んだよ。', translation: "I read everything.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12167975, text: '全部聞いたよ。', translation: "I heard everything.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '大きな': [
    TatoebaSentence(id: 11029578, text: '大きな犬ね。', translation: "It's a big dog.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13089110, text: '大きな家ね。', translation: "It's a big house.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9734923, text: '銀杏は大きな木だよ。', translation: "Ginkgos are large trees.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '文章': [
    TatoebaSentence(id: 12461963, text: '興味深い文章だね。', translation: "That's an interesting sentence.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8734914, text: 'この文章は正しいでしょうか？', translation: "Is this sentence correct?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13184941, text: '文章を書いています。', translation: "I am writing a sentence.", username: 'atitarev', license: 'CC BY 2.0 FR'),
  ],
  '問題': [
    TatoebaSentence(id: 4848, text: '何が問題なの？', translation: "Where is the problem?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 79868, text: '問題ないよ。', translation: "No problem!", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2581823, text: 'それが問題？', translation: "Is that a problem?", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
  ],
  'ください': [
    TatoebaSentence(id: 1678503, text: '塩ください。', translation: "The salt, if you please.", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8583430, text: 'これください。', translation: "I'll take it.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9101656, text: '入ってください！', translation: "Come in.", username: 'tontonton', license: 'CC BY 2.0 FR'),
  ],
  '見る': [
    TatoebaSentence(id: 13250220, text: 'アニメ見る？', translation: "Do you watch anime?", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9935945, text: 'テレビは見るよ。', translation: "I watch television.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 220148, text: 'この番組見る？', translation: "Do you want to watch this program?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '旅行': [
    TatoebaSentence(id: 3309201, text: '旅行は好き？', translation: "Do you like to travel?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 78170, text: '旅行に行こう。', translation: "Let's take a trip.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4751190, text: '旅行どうだった？', translation: "How was your trip?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '家庭': [
    TatoebaSentence(id: 237051, text: '教育は家庭に始まる。', translation: "Education starts at home.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 169168, text: '仕事と家庭どっちが大切なの？', translation: "Which comes first, your career or your family?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10742751, text: '家庭的な料理が好きです。', translation: "I like homemade food.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '番号': [
    TatoebaSentence(id: 124619, text: '電話番号を教えて。', translation: "Give me your phone number.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 121175, text: '番号が違いますよ。', translation: "You have the wrong number.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3576142, text: '部屋番号は５です。', translation: "My room number is 5.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '今年': [
    TatoebaSentence(id: 171362, text: '今年の冬は暖かい。', translation: "This winter is warm.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8619746, text: '今年卒業します。', translation: "I'll graduate this year.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1171014, text: '今年は雨が多い。', translation: "We've had a lot of rain this year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '結婚': [
    TatoebaSentence(id: 3366804, text: '結婚しよう。', translation: "Let's get married.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8697567, text: '結婚するの？', translation: "Are you getting married?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10043162, text: '結婚式はいつ？', translation: "When's the wedding?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '新聞': [
    TatoebaSentence(id: 6828179, text: '新聞を読みます。', translation: "I'm reading the newspaper.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 145180, text: '新聞どこ？', translation: "Where's the newspaper?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9478108, text: '今日の新聞見た？', translation: "Have you seen today's paper?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '一つ': [
    TatoebaSentence(id: 3496837, text: '一つ食べてみよう。', translation: "Let's try one.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3488273, text: '一つ選んで。', translation: "Choose one.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3552046, text: '椅子が一つ欲しい。', translation: "I want a chair.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '名前': [
    TatoebaSentence(id: 4002090, text: '名前は何？', translation: "What is your name?", username: 'oliviya', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 226572, text: 'お名前は？', translation: "May I have your name?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11257985, text: '名前を教えて。', translation: "Tell me your name.", username: 'sh5555', license: 'CC BY 2.0 FR'),
  ],
  '一人': [
    TatoebaSentence(id: 2560046, text: '一人だ。', translation: "I'm alone.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9851622, text: '一人かい？', translation: "Are you alone?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13223996, text: '一人で行く。', translation: "I'll go alone.", username: 'Lumi', license: 'CC BY 2.0 FR'),
  ],
  '便利': [
    TatoebaSentence(id: 205969, text: 'そりゃ便利だね。', translation: "That comes in handy.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9749141, text: 'フランス語は便利よ。', translation: "French is useful.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901804, text: '大きなかばんは便利です。', translation: "A big bag is convenient.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '映画': [
    TatoebaSentence(id: 13523717, text: '映画が好き。', translation: "I love movies.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10614723, text: 'いい映画だね。', translation: "It's a good movie.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8617324, text: '好きな映画は何？', translation: "What are your favorite movies?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ページ': [
    TatoebaSentence(id: 10635051, text: '何ページ？', translation: "What page?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 81661, text: '本のページをめくる。', translation: "I turn over a page of the book.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 235826, text: '１ページ足りない。', translation: "There is a page missing.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  'など': [
    TatoebaSentence(id: 109811, text: '彼は嘘など言わない。', translation: "He doesn't tell lies.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12957183, text: '完璧なものなどない。', translation: "Nothing's perfect.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5023723, text: '完璧な人間などいない。', translation: "Nobody is perfect.", username: 'Imp', license: 'CC BY 2.0 FR'),
  ],
  'でも': [
    TatoebaSentence(id: 1057337, text: 'でもどうして？', translation: "But why?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 202087, text: 'でも高いよ。', translation: "It's expensive though.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1057336, text: 'でもなんで？', translation: "But why?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'なる': [
    TatoebaSentence(id: 2350395, text: 'なるほど。', translation: "I understand.", username: 'hutian', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4944207, text: '大きくなる。', translation: "It's getting bigger.", username: 'reif0nalself', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12098501, text: '夜になる。', translation: "Night's coming.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'では': [
    TatoebaSentence(id: 202140, text: 'ではまた明日。', translation: "See you again tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3506689, text: 'ではまた近々。', translation: "See you soon!", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10911484, text: 'では失礼します。', translation: "Excuse me.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'より': [
    TatoebaSentence(id: 8584535, text: '弟は俺より強い。', translation: "My brother is stronger than me.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11795628, text: '私より5つ上よ。', translation: "He's five years older than me.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 186603, text: '花より団子。', translation: "A loaf of bread is better than the songs of birds.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  'スポーツ': [
    TatoebaSentence(id: 3110652, text: 'スポーツは好き？', translation: "Do you like sports?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 930219, text: 'スポーツが大好きです。', translation: "I love sports.", username: 'ryanwhiting', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10561185, text: 'スポーツは苦手です。', translation: "I am not good at sports.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'よく': [
    TatoebaSentence(id: 3506639, text: 'よく見て。', translation: "Watch closely.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10125458, text: 'よく眠れた？', translation: "Did you sleep well?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1512404, text: 'よく聞いて。', translation: "Listen carefully.", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
  ],
  '後ろ': [
    TatoebaSentence(id: 174302, text: '後ろを見ろ。', translation: "Look back!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 117484, text: '彼の後ろにいる。', translation: "I'm behind him.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11065770, text: '木の後ろだよ。', translation: "I'm behind the tree.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '料理': [
    TatoebaSentence(id: 10548509, text: '料理は面白いよ。', translation: "Cooking is interesting.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11017633, text: '料理できるの？', translation: "Can you cook a meal?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8796775, text: '料理は得意？', translation: "Are you a good cook?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'みんな': [
    TatoebaSentence(id: 2310116, text: 'みんなはどこ？', translation: "Where is everybody?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11056066, text: 'みんな準備完了？', translation: "Is everybody ready?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10764031, text: 'みんな好きよ。', translation: "I like all of them.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ある': [
    TatoebaSentence(id: 1174232, text: 'お金ある？', translation: "Do you have any money?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9740651, text: 'ペンはある？', translation: "Do you have a pen?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7809264, text: '時間ある？', translation: "Are you available?", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  'かわいい': [
    TatoebaSentence(id: 3488316, text: 'かわいい！', translation: "How cute!", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9442966, text: 'かわいい名前ね。', translation: "That's a pretty name.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10450780, text: 'かわいいよね？', translation: "It's pretty, isn't it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '音楽': [
    TatoebaSentence(id: 13254283, text: '音楽が好きです。', translation: "I like music.", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9608080, text: '音楽を聴きたい？', translation: "Do you want to listen to music?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9510653, text: 'どんな音楽が好き？', translation: "What music do you like?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '買い物': [
    TatoebaSentence(id: 9039645, text: '買い物大好き！', translation: "I love shopping!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11256176, text: '買い物に行ってくる。', translation: "I'm going shopping.", username: 'sh5555', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 121495, text: '買い物一緒に行く？', translation: "Would you like to go shopping with me?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '時計': [
    TatoebaSentence(id: 150511, text: '時計が止まった。', translation: "A clock stopped.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10465334, text: '時計してる？', translation: "Are you wearing a watch?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 642471, text: '時計が好きです。', translation: "I like clocks.", username: 'tomkun01', license: 'CC BY 2.0 FR'),
  ],
  '十': [
    TatoebaSentence(id: 3054371, text: 'もう十分よ！', translation: "Enough!", username: 'vencxjo', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13943371, text: '十時間眠った。', translation: "I slept for ten hours.", username: 'HAGNi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8865844, text: '十六歳ですよ。', translation: "I am sixteen years old.", username: 'moxy', license: 'CC BY 2.0 FR'),
  ],
  '新しい': [
    TatoebaSentence(id: 219212, text: 'この卵は新しいよ。', translation: "This egg is fresh.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8619799, text: '新しい車買ったの？', translation: "Did you buy a new car?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8611321, text: '新しい友達はできた？', translation: "Did you make any new friends?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '道': [
    TatoebaSentence(id: 10151278, text: '道を渡った。', translation: "I crossed the street.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13127484, text: '道は閉鎖中だ。', translation: "The road is closed.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9107203, text: '長い道のりだ。', translation: "The road is long.", username: 'tontonton', license: 'CC BY 2.0 FR'),
  ],
  '四': [
    TatoebaSentence(id: 12993390, text: '一、二、三、四、五。', translation: "One, two, three, four, five.", username: 'XZJqz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 921354, text: '四時まで待ちます。', translation: "I'll wait till four o'clock.", username: 'ryanwhiting', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10979890, text: '私の妹は四歳です。', translation: "My younger sister is 4 years old.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '木': [
    TatoebaSentence(id: 3174112, text: 'あれは木です。', translation: "That's a tree.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2080647, text: '木は燃えます。', translation: "Wood burns.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 80143, text: '木が倒れた。', translation: "The tree fell down.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '六': [
    TatoebaSentence(id: 2436329, text: '六時はどうですか。', translation: "How about six o'clock?", username: 'fgreco', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1504934, text: '六時には戻るよ。', translation: "I'll be back at six.", username: 'verbum', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11031385, text: '六時半からです。', translation: "It starts at 6.30.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '年': [
    TatoebaSentence(id: 3583382, text: '一年生です。', translation: "I'm a freshman.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12022237, text: '年末です。', translation: "It's the end of the year.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11825864, text: '一年って、何日？', translation: "How many days are there in a year?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '八': [
    TatoebaSentence(id: 126233, text: '朝の八時です。', translation: "It's eight o'clock in the morning.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10798107, text: '息子は八歳です。', translation: "My son is eight years old.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 650836, text: '午後八時です。', translation: "It's eight o'clock at night.", username: 'arihato', license: 'CC BY 2.0 FR'),
  ],
  '七': [
    TatoebaSentence(id: 992952, text: '私は七時に起きる。', translation: "I get up at 7:00.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 190567, text: '一週間は七日です。', translation: "There are seven days in a week.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13128674, text: '七歳です。', translation: "He's seven years old.", username: 'rul', license: 'CC BY 2.0 FR'),
  ],
  '百': [
    TatoebaSentence(id: 154533, text: '私は彼から百円借りている。', translation: "I owe him 100 yen.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11459584, text: '何百回と聞いてるよ。', translation: "You've told me that a hundred times.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5437138, text: '百も承知です。', translation: "You're telling me.", username: 'yamashin', license: 'CC BY 2.0 FR'),
  ],
  '千': [
    TatoebaSentence(id: 8733219, text: '千円で足りる？', translation: "Is one thousand yen enough?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 141435, text: '千円札くずれますか。', translation: "Can you break a 1000 yen bill?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 205018, text: '全部で三千円です。', translation: "That's 3000 yen altogether.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '海': [
    TatoebaSentence(id: 2397000, text: '海は青いです。', translation: "The sea is blue.", username: 'Hayabusa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10774748, text: '海が見たいな。', translation: "I want to see the sea.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1209141, text: '彼は海が怖い。', translation: "He's afraid of the sea.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '花': [
    TatoebaSentence(id: 8564765, text: 'これは花？', translation: "This is a flower?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11508979, text: '花を買った。', translation: "I bought flowers.", username: 'megamanenm', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1614327, text: '花は黄色い。', translation: "Flowers are yellow.", username: 'Meow', license: 'CC BY 2.0 FR'),
  ],
  '色': [
    TatoebaSentence(id: 10157830, text: '何色なの？', translation: "What colour is it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12988547, text: '黄色です。', translation: "It's yellow.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9992990, text: '灰色が好き。', translation: "I like the color gray.", username: 'moxy', license: 'CC BY 2.0 FR'),
  ],
  '銀行': [
    TatoebaSentence(id: 179575, text: '銀行は９時に開く。', translation: "Banks open at nine o'clock.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9489150, text: '銀行に行かねば。', translation: "I have to go to the bank.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1561542, text: '角に銀行があります。', translation: "There's a bank on the corner.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '自動車': [
    TatoebaSentence(id: 4659110, text: 'これは私の自動車です。', translation: "This is my car.", username: 'anhgosho', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 686575, text: 'あの自動車は彼のものです。', translation: "That is his car.", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1984211, text: '新しい自動車が必要です。', translation: "I need a new car.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '良い': [
    TatoebaSentence(id: 9696844, text: '結果は良い。', translation: "The results are good.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4561577, text: '良い本です。', translation: "It's a good book.", username: 'Kiraness', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 697558, text: '良い一日を。', translation: "Have a nice day.", username: 'arihato', license: 'CC BY 2.0 FR'),
  ],
  '黒': [
    TatoebaSentence(id: 11864856, text: '黒だったよ。', translation: "It was black.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8612279, text: '黒が似合うね。', translation: "Black suits you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1452389, text: '黒猫は好き？', translation: "Do you like black cats?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '九': [
    TatoebaSentence(id: 1483516, text: 'もう九時です。', translation: "It's already nine o'clock.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10979894, text: '私の弟は九歳です。', translation: "My younger brother is 9 years old.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13946753, text: '九時間寝た。', translation: "I slept for 9 hours.", username: 'jan_OkulaJu', license: 'CC BY 2.0 FR'),
  ],
  '北': [
    TatoebaSentence(id: 11589034, text: '北って、どっち？', translation: "Which direction is north?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11804164, text: '北海道に行ってたの？', translation: "Did you go to Hokkaido?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10007420, text: '北京は中国の首都だ。', translation: "Beijing is the capital of China.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
  ],
  '西': [
    TatoebaSentence(id: 138094, text: '太陽は西に沈みます。', translation: "The sun sets in the west.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8216005, text: '私たちは、西へ行く。', translation: "We're going west.", username: 'Tanikaz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 84007, text: '風は西から吹いている。', translation: "The wind is blowing from the west.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '二人': [
    TatoebaSentence(id: 11052135, text: '二人で何してたの？', translation: "What were you two doing?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8748152, text: '二人は友達なの？', translation: "Are you two friends?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 123072, text: '二人は結婚した。', translation: "They got married.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '南': [
    TatoebaSentence(id: 2458802, text: '南駅はどこですか？', translation: "Where is the South Station?", username: 'saturo', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 164302, text: '私の家は南向きです。', translation: "My house looks to the south.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 640529, text: '南アフリカは遠い。', translation: "South Africa is far away.", username: 'arihato', license: 'CC BY 2.0 FR'),
  ],
  '一緒': [
    TatoebaSentence(id: 10608951, text: '一緒に遊ぼう。', translation: "I'll play with you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10741288, text: '一緒に来て。', translation: "Come with me.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10550166, text: '一緒に歌おう。', translation: "Let's sing together.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ニュース': [
    TatoebaSentence(id: 11427736, text: 'ニュース見ないの？', translation: "Haven't you been watching the news?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10177350, text: '今日のニュース見た？', translation: "Did you watch the news today?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9699016, text: 'トムはニュースを見ない。', translation: "Tom doesn't watch the news.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
  ],
  'もっと': [
    TatoebaSentence(id: 13428271, text: 'もっと！', translation: "More!", username: 'demiurgastel', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7486195, text: 'もっと欲しい。', translation: "I want more.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8912639, text: 'もっと見たい？', translation: "Do you want to see more?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '声': [
    TatoebaSentence(id: 2740725, text: 'トムの声がする。', translation: "I can hear Tom.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12593036, text: '子供の声がした。', translation: "I heard a child's voice.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2310031, text: 'トムは声が高い。', translation: "Tom has a high-pitched voice.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '庭': [
    TatoebaSentence(id: 9703388, text: '庭に犬はいないよ。', translation: "There's no dog in the yard.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8735772, text: 'トムは庭にいる？', translation: "Is Tom in the garden?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2786084, text: '私は庭で遊びます。', translation: "I'm playing in the garden.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
  ],
  '青': [
    TatoebaSentence(id: 179417, text: '空は青い。', translation: "The sky is blue.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1394283, text: '車が青い。', translation: "The car is blue.", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6537582, text: '青が好きだ。', translation: "I like blue.", username: 'nihonjin', license: 'CC BY 2.0 FR'),
  ],
  '地図': [
    TatoebaSentence(id: 450691, text: '地図が要ります。', translation: "I need a map.", username: 'Swift', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 126856, text: '地図をかきましょうか？', translation: "Shall I draw a map for you?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9107027, text: '彼なら地図見てるよ。', translation: "He's looking at the map.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '自転車': [
    TatoebaSentence(id: 6828191, text: '自転車がある。', translation: "I have a bike.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10774760, text: '自転車が壊れた。', translation: "My bicycle broke.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2964006, text: 'この自転車、誰の？', translation: "Whose bicycle is this?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '女の子': [
    TatoebaSentence(id: 9069111, text: 'この女の子は誰？', translation: "Who is this girl?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4212028, text: '僕は女の子が好きです。', translation: "I like girls.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12882302, text: '女の子だけだった。', translation: "There were only girls.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '町': [
    TatoebaSentence(id: 882523, text: '町に来ましたか？', translation: "Did you come to town?", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4864645, text: '広い町ね！', translation: "What a large town!", username: 'jarbv', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10466997, text: '町までは遠いよ。', translation: "It's a long way to town.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '言う': [
    TatoebaSentence(id: 778293, text: 'バカ言うな。', translation: "Don't be stupid.", username: 'kenken', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3507486, text: '何も言うな。', translation: "Don't say anything.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8813326, text: '文句を言うな！', translation: "Don't complain.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '春': [
    TatoebaSentence(id: 2654859, text: '春が来た。', translation: "Spring has come.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 483531, text: '春になった。', translation: "Spring is here.", username: 'Swift', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11584388, text: '春は嫌いなんだ。', translation: "I do not like spring.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '英語': [
    TatoebaSentence(id: 13661162, text: '英語を話せます。', translation: "I can speak English.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10212567, text: '英語、話せるよ。', translation: "I can speak English.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 947657, text: '英語の先生です。', translation: "I am an English teacher.", username: 'riccioberto', license: 'CC BY 2.0 FR'),
  ],
  '話': [
    TatoebaSentence(id: 1057280, text: '話してよ！', translation: "Talk to me!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2303034, text: '何の話？', translation: "What are you talking about?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11518966, text: '怪談話して！', translation: "Tell us a ghost story!", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '箱': [
    TatoebaSentence(id: 6828201, text: '箱がある。', translation: "There is a box.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3320916, text: '箱の中身は何？', translation: "What's in the box?", username: 'Tadafumi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3506683, text: '箱を開けて。', translation: "Open the box.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '病院': [
    TatoebaSentence(id: 2604697, text: 'ここは病院です。', translation: "This is a hospital.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 182975, text: '病院に行けよ。', translation: "Go to the hospital.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2466329, text: '病院は何処ですか？', translation: "Where's the hospital?", username: '_s1v3_', license: 'CC BY 2.0 FR'),
  ],
  '半': [
    TatoebaSentence(id: 1874075, text: '３時半です。', translation: "It's 3:30.", username: 'Unaden', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 121255, text: '半分よこせ。', translation: "Give me half of it.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13662181, text: 'もう一時半だ。', translation: "It's already half past one.", username: 'HAGNi', license: 'CC BY 2.0 FR'),
  ],
  '雑誌': [
    TatoebaSentence(id: 82996, text: '母は雑誌を読んでいる。', translation: "My mother is reading a magazine.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1003746, text: 'お店で雑誌を１冊買った。', translation: "I bought a magazine in a store.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 221868, text: 'この雑誌を読みたいの？', translation: "Do you want to read this magazine?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '机': [
    TatoebaSentence(id: 356396, text: 'これは机です。', translation: "This is a desk.", username: 'zipangu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 163877, text: '私の机は古い。', translation: "My desk is old.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9961535, text: 'これは誰の机ですか？', translation: "Whose desk is this?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '動物': [
    TatoebaSentence(id: 11571587, text: '猫は動物です。', translation: "Cats are animals.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9149381, text: '人間は動物です。', translation: "Humans are animals.", username: 'nonong', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9119541, text: '動物、大好きだよ。', translation: "I love animals.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '外国': [
    TatoebaSentence(id: 1178298, text: '外国人だ。', translation: "I am a foreigner.", username: 'treskro3', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 157910, text: '私は外国へ行きたい。', translation: "I want to go abroad.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 108952, text: '彼は外国へ行った。', translation: "He went abroad.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '財布': [
    TatoebaSentence(id: 195947, text: 'ほら財布だ。', translation: "Here's my wallet.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5069, text: '財布をなくしたの。', translation: "I have lost my wallet.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7989452, text: '財布が盗まれた。', translation: "My wallet has been stolen.", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  '大切': [
    TatoebaSentence(id: 11104542, text: 'とても大切だよ。', translation: "It's very important.", username: 'sakifan', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9974917, text: '睡眠は大切だよ。', translation: "Sleep is important.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 137434, text: '大切にします。', translation: "I'll treasure it.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '服': [
    TatoebaSentence(id: 11720953, text: '服を着なさい。', translation: "Put on your clothes.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8612286, text: 'その服いいね。', translation: "I love your outfit.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12593323, text: '服が濡れてる。', translation: "The clothes are wet.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '教室': [
    TatoebaSentence(id: 866831, text: '私は教室にいる。', translation: "I am in the classroom.", username: 'thyc244', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9030583, text: '教室でね。', translation: "See you in class.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10162775, text: '教室から出なさい。', translation: "Get out of the classroom.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '公園': [
    TatoebaSentence(id: 157179, text: '私は公園に行く。', translation: "I go to the park.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11846818, text: '公園には誰もいない。', translation: "There's no one in the park.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10953987, text: '公園に木があります。', translation: "There are trees in the park.", username: 'soueihin', license: 'CC BY 2.0 FR'),
  ],
  '有名': [
    TatoebaSentence(id: 3368796, text: 'あなたは有名ですか？', translation: "Are you famous?", username: 'verbum', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99242, text: '彼は有名になった。', translation: "He became famous.", username: 'kebukebu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10798019, text: '有名な曲よ。', translation: "It's a famous song.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '歌': [
    TatoebaSentence(id: 2568066, text: '歌える。', translation: "I can sing.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10194962, text: '歌が聞こえる？', translation: "Can you hear the song?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1015795, text: '歌って踊ろう！', translation: "Let's sing and dance.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '村': [
    TatoebaSentence(id: 10633379, text: '彼は村に住んでいます。', translation: "He lives in a village.", username: 'danieru2462', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9846163, text: '僕はこの村が嫌いです。', translation: "I hate this village.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 126109, text: '町は村よりも大きい。', translation: "Towns are larger than villages.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '医者': [
    TatoebaSentence(id: 158511, text: '私は医者です。', translation: "I'm a doctor.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 84640, text: '父は医者です。', translation: "My father is a doctor.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 190903, text: '医者には行ったの？', translation: "Did you go to the doctor?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '靴': [
    TatoebaSentence(id: 179237, text: '靴を履いて。', translation: "Put on your shoes.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10032536, text: '靴が買いたい。', translation: "I want to buy some shoes.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2739683, text: 'これトムの靴？', translation: "Are these Tom's shoes?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '大好き': [
    TatoebaSentence(id: 1661532, text: '大好き。', translation: "I love you.", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 137571, text: '大好きだよ！', translation: "I love you.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 119670, text: '彼が大好き！', translation: "I really like him!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'どう': [
    TatoebaSentence(id: 778978, text: 'どうして？', translation: "Why?", username: 'marloncori', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5675039, text: 'どう？', translation: "How do you like it?", username: 'abyssalalice', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 201105, text: 'どう思う？', translation: "Now, what do you think?", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '玄関': [
    TatoebaSentence(id: 203197, text: 'だれか玄関にいる。', translation: "Someone is at the door.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 137096, text: '誰かが玄関にいるよ。', translation: "Someone is at the front door.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11682468, text: '玄関の鍵はかけたよ。', translation: "I locked the front door.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '兄弟': [
    TatoebaSentence(id: 2975999, text: '兄弟はいません。', translation: "I don't have any brothers.", username: 'Fukuko', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 165892, text: '私たちは兄弟です。', translation: "We are brother and sister.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8534731, text: '兄弟はいますか？', translation: "Do you have any brothers?", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
  ],
  '読む': [
    TatoebaSentence(id: 7422065, text: '読むのを止めなさい。', translation: "Stop reading.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10129724, text: '週に３冊本を読むよ。', translation: "I read three books a week.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 236725, text: '読む本がありますか。', translation: "Do you have any books to read?", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '秋': [
    TatoebaSentence(id: 148220, text: '秋になりました。', translation: "Autumn is here.", username: 'Ianagisacos', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11910301, text: '秋が好きです。', translation: "I like autumn.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901732, text: '秋は涼しいです。', translation: "Autumn is cool.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '練習': [
    TatoebaSentence(id: 12608348, text: 'トムは練習が必要だな。', translation: "Tom needs to practice.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11351942, text: 'もっと練習しなくっちゃ。', translation: "I need to practise more.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99786, text: '彼は毎日家で練習した。', translation: "He practiced every day at home.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '雨': [
    TatoebaSentence(id: 1614573, text: '雨は好き？', translation: "Do you like rain?", username: 'Meow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2562842, text: '雨降ってる？', translation: "Is it raining?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12476815, text: '今日も雨だ。', translation: "It's raining again today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ちょっと': [
    TatoebaSentence(id: 10465520, text: 'ちょっと待てよ！', translation: "Wait a bit!", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 202709, text: 'ちょっと来て。', translation: "Come here.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12296519, text: 'ちょっといい？', translation: "Is it alright if I take a minute?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '雪': [
    TatoebaSentence(id: 468677, text: '雪が降る。', translation: "It's snowing.", username: 'Namikaze', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3029987, text: '外は雪だよ。', translation: "It's snowing outside.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8666140, text: '雪が深い。', translation: "The snow is deep.", username: 'ajje', license: 'CC BY 2.0 FR'),
  ],
  'お金': [
    TatoebaSentence(id: 13511293, text: 'お金がない。', translation: "I don't have any money.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1174227, text: 'お金持ってる？', translation: "Do you have any money?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 227268, text: 'お金が欲しい。', translation: "I want money.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '縦': [
    TatoebaSentence(id: 10022278, text: '首を縦に振るのは同意のサインだ。', translation: "A nod is a sign of agreement.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10617741, text: 'トムは、うんうんと首を縦に振っている。', translation: "Tom is nodding his head.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10979897, text: '縦長の箱ってこれですか？', translation: "Is it this oblong box?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '出口': [
    TatoebaSentence(id: 3549611, text: '出口はどこですか？', translation: "Where is the exit?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12522149, text: '出口を探そう。', translation: "Let's find the exit.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8724072, text: '他の出口はありますか？', translation: "Is there another exit?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],

  // JLPT N5 Vocabulary continued (words 151-300 of the set) - again only
  // the words not already covered above.
  '川': [
    TatoebaSentence(id: 9382514, text: '川に行こうよ。', translation: "Let's go to the river.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 208499, text: 'その川は広い。', translation: "The river is wide.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10198754, text: '川って、きれいね。', translation: "The river is beautiful.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'いつ': [
    TatoebaSentence(id: 5675040, text: 'いつ？', translation: "When?", username: 'abyssalalice', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11460081, text: 'いつ来たの？', translation: "When did you come?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 14014943, text: 'いつも。', translation: "Always.", username: 'kris514', license: 'CC BY 2.0 FR'),
  ],
  '午後': [
    TatoebaSentence(id: 174389, text: '午後は休みだった。', translation: "We had the afternoon off.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 174380, text: '午後二時です。', translation: "It's two o'clock in the afternoon.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9007673, text: '午後って空いてる？', translation: "Are you free in the afternoon?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '角': [
    TatoebaSentence(id: 213634, text: 'そこの角ですよ。', translation: "It's at the corner.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1561542, text: '角に銀行があります。', translation: "There's a bank on the corner.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10565412, text: '次の角を左に曲がって。', translation: "Turn left at the next corner.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '肉': [
    TatoebaSentence(id: 11156553, text: '肉は、旨い。', translation: "Meat tastes good.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11512580, text: '肉が安い。', translation: "The meat is cheap.", username: 'megamanenm', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 14000021, text: '肉を入れて。', translation: "Add meat.", username: 'jan_OkulaJu', license: 'CC BY 2.0 FR'),
  ],
  '鍵': [
    TatoebaSentence(id: 12403571, text: '鍵ある？', translation: "Do you have the keys?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11469097, text: 'これ、誰の鍵？', translation: "Whose key is this?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9458434, text: '鍵を開けろ。', translation: "Unlock it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '始め': [
    TatoebaSentence(id: 1683427, text: '始めました。', translation: "It has begun.", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 442923, text: '始めましょう。', translation: "Let's begin.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 168951, text: '始めが肝心。', translation: "A good beginning makes a good ending.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '駅': [
    TatoebaSentence(id: 158266, text: '駅に着いたよ。', translation: "I arrived at the station.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 188894, text: '駅はどこですか。', translation: "Where is the railroad station?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2226546, text: '私は駅に行った。', translation: "I went to the station.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '大人': [
    TatoebaSentence(id: 2337382, text: 'トムは大人だ。', translation: "Tom is an adult.", username: 'DiePain', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 177535, text: '君はもう大人だ。', translation: "You are now an adult.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1218912, text: '大人になってよ！', translation: "Grow up!", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '横': [
    TatoebaSentence(id: 3506681, text: 'さあ横になって。', translation: "Now lie down.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9732763, text: '横に座って。', translation: "Sit beside me.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 188522, text: '横向きに寝る。', translation: "I sleep on my side.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '天気': [
    TatoebaSentence(id: 2173966, text: 'いい天気です。', translation: "It's a nice day.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8763912, text: '天気はいい？', translation: "Is the weather nice?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8697825, text: '天気は良かった？', translation: "Was the weather nice?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'カメラ': [
    TatoebaSentence(id: 9949490, text: 'いいカメラだね。', translation: "You have a good camera.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8588677, text: 'カメラを買いたいな。', translation: "I'd like to buy a camera.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10895580, text: 'これは誰のカメラ？', translation: "Whose camera is this?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '他': [
    TatoebaSentence(id: 8718358, text: '他に何かあるの？', translation: "Is there something else?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2750248, text: '他に質問はある？', translation: "Have you any further questions?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8667779, text: '他に誰かいるの？', translation: "Is there anyone else?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'テレビ': [
    TatoebaSentence(id: 9935945, text: 'テレビは見るよ。', translation: "I watch television.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8748192, text: 'テレビ見てるの？', translation: "Are you watching TV?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11531493, text: 'テレビは消した？', translation: "Did you turn off the TV?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '去年': [
    TatoebaSentence(id: 90501, text: '彼女は去年結婚した。', translation: "She got married last year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 182213, text: '去年は雨が多かった。', translation: "We had a lot of rain last year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11005193, text: '去年はいい年でした。', translation: "Last year was a good year.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '今月': [
    TatoebaSentence(id: 171520, text: '今月は売上が落ちた。', translation: "Sales are down this month.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 172450, text: '今月は給料が多かった。', translation: "My salary was high this month.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11031521, text: '今月は何月ですか？', translation: "What is the current month?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '午前': [
    TatoebaSentence(id: 9755627, text: '午前８時です。', translation: "It's 8:00 am.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10580046, text: '午前中は家にいます。', translation: "I'll be at home in the morning.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2228656, text: '彼は午前中に起きた。', translation: "He got up in the morning.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '少ない': [
    TatoebaSentence(id: 235158, text: '５は８より少ない。', translation: "5 is less than 8.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2378178, text: '僕は友達が少ない。', translation: "I don't have many friends.", username: 'nysjisi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 162838, text: '私の父は口数が少ない。', translation: "My father is a man of few words.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '大変': [
    TatoebaSentence(id: 347139, text: '大変疲れた。', translation: "I'm exhausted.", username: 'zhouj1955', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 171553, text: '今日は大変寒い。', translation: "It's awfully cold today.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11257874, text: 'わぁ！大変だ！', translation: "Ah! This is bad!", username: 'sh5555', license: 'CC BY 2.0 FR'),
  ],
  '元気': [
    TatoebaSentence(id: 3495032, text: '元気です。', translation: "I'm doing fine.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 175045, text: '元気？', translation: "How is it going?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 227185, text: 'お元気で！', translation: "Good luck to you!", username: 'verbum', license: 'CC BY 2.0 FR'),
  ],
  '河': [
    TatoebaSentence(id: 9940163, text: 'トムが河にナイフを捨てたのよ。', translation: "Tom threw the knife in the river.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 186771, text: '河川は豪雨で氾濫しました。', translation: "The rivers were flooded by the heavy rain.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1808694, text: '私たちは銀河に住んでいます。', translation: "We live in a galaxy.", username: 'nonong', license: 'CC BY 2.0 FR'),
  ],
  '野菜': [
    TatoebaSentence(id: 1991994, text: '野菜を食べなさい。', translation: "Eat your vegetables.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10194977, text: 'ニンジンは野菜です。', translation: "Carrots are vegetables.", username: 'h_aibe', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2759288, text: '好きな野菜は何ですか？', translation: "What's your favorite vegetable?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '出す': [
    TatoebaSentence(id: 173912, text: '口を出すな。', translation: "You keep out of this.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 140406, text: '窓から顔を出すな。', translation: "Don't put your head out of the window.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11674952, text: '今日は、僕が出すよ。', translation: "Today I'm paying.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'テーブル': [
    TatoebaSentence(id: 229736, text: 'あれはテーブルです。', translation: "That is a table.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 202412, text: 'テーブルの下よ。', translation: "It's under the table.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9314791, text: 'テーブルにつきなさい。', translation: "Sit at the table.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '病気': [
    TatoebaSentence(id: 6549720, text: '私は病気です。', translation: "I am sick.", username: 'nebby', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8671293, text: 'トムは病気だ。', translation: "Tom is sick.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7870114, text: '病気になった。', translation: "I got sick.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
  ],
  '男の子': [
    TatoebaSentence(id: 10633458, text: '男の子ですよ。', translation: "It's a boy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3573657, text: 'あの男の子は誰？', translation: "Who is that boy?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10633459, text: '元気な男の子ですよ。', translation: "He is a lively boy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '一': [
    TatoebaSentence(id: 9776983, text: '一口どう？', translation: "How about a bite?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4765273, text: 'もう一度？', translation: "Again?", username: 'Doremi391', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13080191, text: 'もう一回！', translation: "Again!", username: 'KTCXMX', license: 'CC BY 2.0 FR'),
  ],
  '結構': [
    TatoebaSentence(id: 4561616, text: '結構です。', translation: "It's fine.", username: 'Kiraness', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 205734, text: 'それで結構です。', translation: "That will do.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 229316, text: 'いえ、結構です。', translation: "No, thank you.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '交番': [
    TatoebaSentence(id: 174098, text: '交番はどこにあるかわかりますか。', translation: "Do you know where the police station is?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 80229, text: '迷子の子が交番でしくしく泣いていた。', translation: "A lost child was sobbing at the police box.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 174100, text: '交番の周りに人がたくさんいた。', translation: "I saw a number of people around the police box.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  // Covers both this set's '一日' Items: ついたち (1st of the month) and
  // いちにち (one day) - the map only keys on the word text, not the
  // reading, so one entry has to serve both meanings.
  '一日': [
    TatoebaSentence(id: 168964, text: '四月一日です。', translation: "It's April first.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 109880, text: '彼は一日中眠った。', translation: "He slept all day.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3574901, text: '一日何時間寝てる？', translation: "How many hours a day do you sleep?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'ペット': [
    TatoebaSentence(id: 188081, text: '何かペットを飼っていますか。', translation: "Do you have any pets?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5598833, text: 'ペットを飼っていますか。', translation: "Do you have any pets?", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3561952, text: 'ペット飼ったことある？', translation: "Have you ever had a pet?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'もう': [
    TatoebaSentence(id: 8571511, text: 'もう。', translation: "Not again.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8831965, text: 'もう５時？', translation: "Is it five already?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9614904, text: 'もう嫌だ！', translation: "No more!", username: 'Sim5634', license: 'CC BY 2.0 FR'),
  ],
  'そば': [
    TatoebaSentence(id: 2263370, text: 'いつもそばにいるよ。', translation: "I will always be there for you.", username: 'verbum', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8508435, text: 'そばにいたいな。', translation: "I want to be near you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 126788, text: '池のそばに男がいる。', translation: "There is a man by the side of the pond.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
  ],
  '建物': [
    TatoebaSentence(id: 231063, text: 'あの建物を見て。', translation: "Look at that building.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4024248, text: 'あの建物は何ですか？', translation: "What's that building?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11582487, text: 'かなり古い建物です。', translation: "It's quite an old building.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '休み': [
    TatoebaSentence(id: 80438, text: '明日は休みだ。', translation: "It is a holiday tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8967772, text: '休みがある。', translation: "I have the day off.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 190670, text: '一休みしよう。', translation: "Let's take a rest.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'シャツ': [
    TatoebaSentence(id: 11795609, text: 'シャツの色は何色？', translation: "What color is your shirt?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 215873, text: 'シャツ、裏返しよ。', translation: "Your shirt is inside out.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8971932, text: 'このシャツ欲しいな。', translation: "I want this shirt.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'いかが': [
    TatoebaSentence(id: 217184, text: 'ご機嫌いかが？', translation: "How are you?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 195044, text: 'ミルクはいかが？', translation: "How about some milk?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8729105, text: 'スープはいかが？', translation: "Would you like some soup?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '紙': [
    TatoebaSentence(id: 151216, text: '紙がほしい。', translation: "I need some paper.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1272425, text: '紙が必要だ。', translation: "I need some paper.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9703841, text: 'みんな紙はある？', translation: "Does everybody have paper?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '来年': [
    TatoebaSentence(id: 9665658, text: '私たちは来年出る。', translation: "We're leaving next year.", username: 'moxy', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 86330, text: '彼女は来年結婚する。', translation: "She'll be getting married next year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 152388, text: '来年外国へ行きます。', translation: "I will go abroad next year.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '帽子': [
    TatoebaSentence(id: 764160, text: '君の帽子はどれ？', translation: "Which hat is yours?", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10049528, text: '帽子をとりなさい。', translation: "Take your hats off.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10032543, text: '帽子が買いたいの。', translation: "I want to buy a hat.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '上手': [
    TatoebaSentence(id: 9551346, text: '上手に泳げるの？', translation: "Can you swim well?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901736, text: '妹は絵が上手です。', translation: "My younger sister is good at drawing.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 98857, text: '彼は話が上手い。', translation: "He is a good speaker.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '外国人': [
    TatoebaSentence(id: 1178298, text: '外国人だ。', translation: "I am a foreigner.", username: 'treskro3', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9479509, text: '僕ら、外国人じゃないよ。', translation: "We aren't foreigners.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 90732, text: '彼女は外国人と結婚している。', translation: "She is married to a foreigner.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '冬': [
    TatoebaSentence(id: 10622629, text: '冬が終わった。', translation: "Winter is over.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9725744, text: '冬は寒いよ。', translation: "It's cold in the winter.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11970315, text: '冬生まれです。', translation: "I was born in the winter.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '掃除': [
    TatoebaSentence(id: 84106, text: '部屋を掃除しなさい。', translation: "Clean up the room.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10176674, text: '掃除機かけなきゃ。', translation: "I need to vacuum.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10553461, text: '掃除、手伝ってよ。', translation: "Help me clean up.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '皆さん': [
    TatoebaSentence(id: 184979, text: '皆さんはお元気？', translation: "How is everyone?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9107204, text: '皆さんこんにちは。', translation: "Hello everyone.", username: 'tontonton', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 184991, text: '皆さんおはよう。', translation: "Good morning, everybody.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '痛い': [
    TatoebaSentence(id: 7551811, text: '痛い。', translation: "That hurts.", username: 'Kitsuneko', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1086947, text: '目が痛い！', translation: "My eyes hurt!", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11574659, text: '歯が痛いの？', translation: "Do you have a toothache?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '難しい': [
    TatoebaSentence(id: 3506562, text: '難しいわ。', translation: "It's so hard.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10386935, text: 'それは難しいね。', translation: "That's hard.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9431904, text: 'チェスは難しい。', translation: "Chess is hard.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '欲しい': [
    TatoebaSentence(id: 3552884, text: '何が欲しいの？', translation: "What do you want?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 178853, text: '君が欲しい。', translation: "I want you.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12206265, text: 'これ欲しい？', translation: "Do you want this?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'かばん': [
    TatoebaSentence(id: 164225, text: '私のかばんです。', translation: "This is my bag.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4216181, text: 'かばんを返せ。', translation: "Give me back my bag.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10701146, text: 'かばん、重たっ！', translation: "What a heavy bag!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '二つ': [
    TatoebaSentence(id: 10880137, text: '二つだけだったよ。', translation: "There were only two.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10557655, text: '二つともタダだよ。', translation: "They're both free.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2261087, text: '席が二つ空いていた。', translation: "Two seats were vacant.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '今週': [
    TatoebaSentence(id: 3024516, text: '今週末は暇？', translation: "Are you free this weekend?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10097988, text: '今週は忙しいのよ。', translation: "I'm busy this week.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8749689, text: '今週は忙しい？', translation: "Are you busy this week?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'コート': [
    TatoebaSentence(id: 224953, text: 'コートを脱ぎなさい。', translation: "Take off your coat.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 229407, text: 'いいコートだね。', translation: "That's a nice coat.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8815991, text: 'それ、トムのコート？', translation: "Is that Tom's coat?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '食べ物': [
    TatoebaSentence(id: 2242433, text: 'これは食べ物です。', translation: "This is food.", username: 'wool', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3114647, text: '好きな食べ物は？', translation: "What's your favorite food?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5675031, text: '食べ物！', translation: "Food!", username: 'abyssalalice', license: 'CC BY 2.0 FR'),
  ],
  '多い': [
    TatoebaSentence(id: 13111655, text: '多い！', translation: "A lot!", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1171014, text: '今年は雨が多い。', translation: "We've had a lot of rain this year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11263452, text: '山の多い国です。', translation: "It's a very mountainous country.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '図書館': [
    TatoebaSentence(id: 13228496, text: 'ここは図書館です。', translation: "This is a library.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8746567, text: '図書館にいるの？', translation: "Are you in the library?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10759889, text: '図書館にはいつ行くの？', translation: "When are you going to the library?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '黄色': [
    TatoebaSentence(id: 12988547, text: '黄色です。', translation: "It's yellow.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2739599, text: '私は黄色が好きです。', translation: "I like the colour yellow.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 553870, text: 'バナナは黄色です。', translation: "Bananas are yellow.", username: 'Namikaze', license: 'CC BY 2.0 FR'),
  ],
  '洗濯': [
    TatoebaSentence(id: 11053957, text: '洗濯機は買ったの？', translation: "Did you buy a washing machine?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10615967, text: '洗濯物干したよ。', translation: "We hung up the laundry.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11795601, text: '今日は、洗濯した？', translation: "Did you wash clothes today?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '初め': [
    TatoebaSentence(id: 10735526, text: '誰が初めに来たの？', translation: "Which of you was here first?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9089506, text: 'まず初めに、名前を書きなさい。', translation: "Write your name, first of all.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 86344, text: '彼女は来月の初めに東京に着く。', translation: "She will arrive in Tokyo at the beginning of next month.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '妹': [
    TatoebaSentence(id: 81415, text: '妹さんは元気？', translation: "How's your sister?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4521322, text: '妹は美人だ。', translation: "My sister is pretty.", username: 'atomsk', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6705562, text: '妹が三人いる。', translation: "I have three younger sisters.", username: 'lucasmg123', license: 'CC BY 2.0 FR'),
  ],
  '窓': [
    TatoebaSentence(id: 9700577, text: 'あれは窓だよ。', translation: "That is a window.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 140336, text: '窓を閉めて。', translation: "Close the window.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 140363, text: '窓を開けて。', translation: "Open the window.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
  ],
  '授業': [
    TatoebaSentence(id: 10911461, text: '授業が始まるぞ。', translation: "Class is about to start.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 86004, text: '彼等は授業中だ。', translation: "They are in class.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12301148, text: '次の授業は何ですか？', translation: "What is the next class?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '耳': [
    TatoebaSentence(id: 1148685, text: '壁に耳あり。', translation: "The walls have ears.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11978262, text: '耳を疑った。', translation: "I could not believe my ears.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1326876, text: '初耳だ。', translation: "That's news to me.", username: 'Scott', license: 'CC BY 2.0 FR'),
  ],
  '広い': [
    TatoebaSentence(id: 11256098, text: '世界は広い。', translation: "The world is vast.", username: 'sh5555', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 173631, text: '広いな！', translation: "God, this place is huge!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901728, text: '空は広いです。', translation: "The sky is big.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '飛行機': [
    TatoebaSentence(id: 85733, text: '飛行機が見えた。', translation: "I saw a plane.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6828226, text: '飛行機に乗ります。', translation: "I'll ride a plane.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12829730, text: '飛行機に遅れた。', translation: "I missed the plane.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '洋服': [
    TatoebaSentence(id: 219225, text: 'この洋服はお買い得です。', translation: "This dress is a good bargain.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 236922, text: 'とてもすてきな洋服ですね。', translation: "That's a beautiful dress.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10177047, text: 'お洋服着ましょうね。', translation: "Let's get you dressed.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '階段': [
    TatoebaSentence(id: 6828200, text: '階段がある。', translation: "There are stairs.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 184907, text: '階段を上がって。', translation: "Go up the stairs.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8663981, text: '階段から落ちたよ。', translation: "I fell down the stairs.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ボタン': [
    TatoebaSentence(id: 10733637, text: 'ボタンを押す。', translation: "Press the button.", username: 'megamanenm', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 196248, text: 'ボタンが取れた。', translation: "The button came off.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 196247, text: 'ボタンに触れるな！', translation: "Don't touch that button!", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '緑': [
    TatoebaSentence(id: 13541053, text: '木は緑色です。', translation: "The trees are green.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11776653, text: '緑です。', translation: "It's green.", username: 'mashi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10667345, text: 'それらは緑色だ。', translation: "They're green.", username: 'YT', license: 'CC BY 2.0 FR'),
  ],
  '取る': [
    TatoebaSentence(id: 2972338, text: 'どっち取る？', translation: "Which one do you take?", username: 'Fukuko', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10910324, text: '出席を取るぞ。', translation: "I'll take attendance.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 205421, text: '取るに足らない問題です。', translation: "That is a trivial problem.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '呼ぶ': [
    TatoebaSentence(id: 2060895, text: '私をトムと呼ぶのはやめて。', translation: "Stop calling me Tom.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 105604, text: '彼は私をピートと呼ぶ。', translation: "He calls me Pete.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 194914, text: 'みんな彼をマックと呼ぶ。', translation: "Everybody calls him Mac.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '生徒': [
    TatoebaSentence(id: 199875, text: 'トムは生徒です。', translation: "Tom is a student.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 230675, text: 'あの生徒がトムです。', translation: "That student is Tom.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8572286, text: '先生ですか？それとも生徒？', translation: "Are you a teacher or a student?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'お茶': [
    TatoebaSentence(id: 9611446, text: 'お茶です。', translation: "It's tea.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3455875, text: 'お茶が飲みたい。', translation: "I want to have some tea.", username: 'tomo', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12461936, text: 'お茶の時間よ。', translation: "It's time for tea.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '二日': [
    TatoebaSentence(id: 236852, text: '二日酔いだ。', translation: "I have a hangover.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 123013, text: '二日後に彼は帰ってきた。', translation: "He came back two days after.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1229048, text: '二日ほど休みをとります。', translation: "I am taking a couple of days off.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '両親': [
    TatoebaSentence(id: 1174885, text: 'ご両親は元気ですか。', translation: "How are your parents?", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1698955, text: '両親は離婚しました。', translation: "My parents are divorced.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10917251, text: '両親に電話して。', translation: "Call your parents.", username: 'SomeHungryBois', license: 'CC BY 2.0 FR'),
  ],
  '三つ': [
    TatoebaSentence(id: 217647, text: 'これを三つください。', translation: "I'd like three of these.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7704557, text: '三つの選択肢があります。', translation: "There are three options.", username: 'leafjensen', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1255283, text: 'その机には引き出しが三つある。', translation: "The desk has three drawers.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'こちら': [
    TatoebaSentence(id: 1483688, text: 'こちらへどうぞ。', translation: "This way, please.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 224174, text: 'こちらに来なさい。', translation: "Come here.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 373214, text: 'こちらは母です。', translation: "This is my mother.", username: 'kotobaboke', license: 'CC BY 2.0 FR'),
  ],
  '毎週': [
    TatoebaSentence(id: 8973468, text: '毎週月曜日はテニスをします。', translation: "I play tennis every Monday.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99833, text: '彼は毎週車を洗います。', translation: "He washes the car every week.", username: 'riccioberto', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9171218, text: '毎週それをしてるんだ。', translation: "I do that every week.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '魚': [
    TatoebaSentence(id: 10798099, text: '魚は泳げます。', translation: "Fish can swim.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6828205, text: '魚を食べる。', translation: "I eat fish.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10574136, text: '魚がいるよ。', translation: "There's a fish.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '丈夫': [
    TatoebaSentence(id: 9947183, text: '牛乳は私たちの体を丈夫にしてくれます。', translation: "Milk makes us strong.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10640353, text: 'これは、丈夫な手すりだ。', translation: "This is a sturdy handrail.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 635035, text: '体が丈夫な限りはがんばりたいです。', translation: "I want to try my best for as long as I am physically able to.", username: 'blay_paul', license: 'CC BY 2.0 FR'),
  ],
  '時々': [
    TatoebaSentence(id: 4730, text: '彼は時々変です。', translation: "Sometimes he can be a strange guy.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 633075, text: '時々ＴＶを見る。', translation: "I watch TV now and then.", username: 'blay_paul', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10919606, text: 'トムは時々泣く。', translation: "Tom sometimes cries.", username: 'SomeHungryBois', license: 'CC BY 2.0 FR'),
  ],
  '初めて': [
    TatoebaSentence(id: 10572146, text: '初めて来たの？', translation: "Is this the first time you've been here?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8725990, text: 'ここは初めてですか？', translation: "Is this your first time here?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 792512, text: '初めて作りました。', translation: "I made it for the first time.", username: 'ryanthewired', license: 'CC BY 2.0 FR'),
  ],
  '手紙': [
    TatoebaSentence(id: 12142995, text: '手紙、読んだよ。', translation: "I read your letter.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1572989, text: '彼は手紙を書く。', translation: "He writes a letter.", username: 'Zaghawa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 233743, text: '彼から手紙がきた？', translation: "You heard from him?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '門': [
    TatoebaSentence(id: 3495554, text: '門を閉めて。', translation: "Close the gate.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3496856, text: '開門しなさい。', translation: "Open the gate.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8572349, text: '門の前で待つよ。', translation: "I'll wait for you at the front gate.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '夏休み': [
    TatoebaSentence(id: 194438, text: 'もうすぐ夏休みです。', translation: "Soon there will be summer vacation.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 187172, text: '夏休みはどうだった？', translation: "How was your summer vacation?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1125951, text: '夏休みが終わった。', translation: "The summer vacation is over.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '絵': [
    TatoebaSentence(id: 10108510, text: 'これは絵だよ。', translation: "This is a painting.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 184939, text: '絵を見なさい。', translation: "Look at the picture.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3655414, text: 'きれいな絵だ。', translation: "That's a beautiful painting.", username: 'tonymanga83', license: 'CC BY 2.0 FR'),
  ],
  '先月': [
    TatoebaSentence(id: 8437823, text: '先月ボストンに来ました。', translation: "I came to Boston last month.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1174266, text: '先月引っ越しました。', translation: "I changed my address last month.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10804261, text: '会議は先月でしたよ。', translation: "The meeting was last month.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'こんな': [
    TatoebaSentence(id: 2298302, text: 'こんなの信じない。', translation: "I don't believe this.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8730579, text: 'いつもこんな感じ？', translation: "Is it always like this?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9826860, text: 'こんなの簡単よ。', translation: "This is easy for me.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '十日': [
    TatoebaSentence(id: 10932446, text: '誕生日は、十一月十日です。', translation: "My birthday is November 10th.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10489393, text: '明日は十月十日火曜日です。', translation: "Tomorrow is Tuesday, the tenth of October.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 184391, text: '学校は四月十日から始まります。', translation: "School begins on April the tenth.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '毎月': [
    TatoebaSentence(id: 9640691, text: '毎月給料をもらいます。', translation: "I get paid every month.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 81361, text: '毎月のガス代はいくらですか。', translation: "How much is your monthly gas bill?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 152873, text: '私は母から毎月便りをもらう。', translation: "I hear from my mother every month.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  // 七日 (なのか) is rare in the corpus as a literal match - these 3 are
  // the only genuine hits, one borrowed from a 十七日 (17th) sentence.
  '七日': [
    TatoebaSentence(id: 190567, text: '一週間は七日です。', translation: "There are seven days in a week.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 910443, text: 'この年の正月は十四日から十七日まで四日間の雪を見た。', translation: "In the first month of that year, I saw that it snowed for four days from the 14th until the 17th.", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10846444, text: '最近では、故人が亡くなってから７日目に行う初七日法要を葬儀当日に済ませることが多くなっています。', translation: "It has recently become common to hold the Buddhist seventh-day memorial service on the same day as the funeral.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '台所': [
    TatoebaSentence(id: 137831, text: '台所にいます。', translation: "They are in the kitchen.", username: 'KF', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8532899, text: '台所はどこ？', translation: "Where's the kitchen?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 137826, text: '台所に猫がいる。', translation: "There is a cat in the kitchen.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
  ],
  '作文': [
    TatoebaSentence(id: 9464059, text: '作文は書き終わりましたか？', translation: "Have you finished writing your composition?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 100056, text: '彼は報告書を作文した。', translation: "He wrote the report.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10899681, text: 'この作文はとてもよく書けてますね。', translation: "This essay is very well written.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  // 九日 (ここのか) is genuinely scarce in the corpus - only these 2
  // sentences contain the literal word, and neither has an English
  // translation linked on Tatoeba.
  '九日': [
    TatoebaSentence(id: 11021436, text: '来月九日に両親がわたしのうちへ遊びに来ます。', username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11211774, text: 'その一は、明治三十七年の九月八日か九日の夜とおぼえている。', username: 'ITA', license: 'CC BY 2.0 FR'),
  ],
  '来月': [
    TatoebaSentence(id: 78691, text: '来月お会いしましょう。', translation: "I'll see you next month.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10045006, text: 'トムは来月結婚します。', translation: "Tom will get married next month.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99126, text: '彼は来月試験を受ける。', translation: "He goes in for the examination next month.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '静か': [
    TatoebaSentence(id: 1484861, text: '静かに。', translation: "Be quiet!", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9378984, text: '今は、静かです。', translation: "It's quiet now.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 234360, text: 'あたりは静かだ。', translation: "All is quiet.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '果物': [
    TatoebaSentence(id: 1634740, text: '果物が好きです。', translation: "I like fruit.", username: 'ari_diary', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10454428, text: 'リンゴは果物です。', translation: "An apple is a fruit.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9687359, text: '好きな果物は？', translation: "What's your favorite fruit?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'なぜ': [
    TatoebaSentence(id: 778976, text: 'なぜ？', translation: "Why?", username: 'marloncori', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 199165, text: 'なぜ遅れたの？', translation: "Why were you late?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1596597, text: 'なぜ聞くの？', translation: "Why do you ask?", username: 'Bah_Dure', license: 'CC BY 2.0 FR'),
  ],
  // 八日 (ようか) is likewise scarce - 2 of these 3 have no linked English
  // translation on Tatoeba.
  '八日': [
    TatoebaSentence(id: 9472440, text: '日本では、八月八日はヒゲの日です。', translation: "August eighth is Beard Day in Japan.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10640428, text: 'トムのお父さんは、八日間の海外出張を終え、無事家に戻ってきました。', username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1700452, text: '五月の八日は第二次世界大戦が終わった記念日なので、フランスでは祭日です。', username: 'Christophe', license: 'CC BY 2.0 FR'),
  ],
  '眼鏡': [
    TatoebaSentence(id: 163890, text: '私の眼鏡はどこ？', translation: "Where are my glasses?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11529832, text: '眼鏡はかけていますか？', translation: "Do you wear glasses?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 108703, text: '彼は眼鏡を外した。', translation: "He took off his glasses.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '地下鉄': [
    TatoebaSentence(id: 127015, text: '地下鉄に乗ろう。', translation: "Let's take the subway.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3357771, text: '地下鉄に乗るのは嫌いだ。', translation: "I hate riding the subway.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11706810, text: '地下鉄はほぼ毎日乗ってるよ。', translation: "I take the subway almost every day.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '夕方': [
    TatoebaSentence(id: 79043, text: '夕方の五時です。', translation: "It's five in the evening.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99205, text: '彼は夕方遅く帰宅した。', translation: "He came home late in the evening.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8930828, text: '明日の夕方には戻るよ。', translation: "I'll be back tomorrow evening.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'ゼロ': [
    TatoebaSentence(id: 904998, text: '一の前はゼロです。', translation: "Zero comes before one.", username: 'jessie0422', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11056093, text: 'これは、カロリーゼロです。', translation: "This has zero calories.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 997280, text: 'あなたの口座の残高はゼロだ。', translation: "Your account is empty.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '戸': [
    TatoebaSentence(id: 1017188, text: '戸を開けて。', translation: "Open the door.", username: 'yurusu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 174533, text: '戸を閉めろ。', translation: "Shut the door.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 174536, text: '戸を叩く音がした。', translation: "I heard a knock at the door.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '売る': [
    TatoebaSentence(id: 11831405, text: '売ることにしたんだ。', translation: "We decided to sell it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 158021, text: '私は家を売るつもりです。', translation: "I'm going to sell my house.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6037346, text: '彼は果物を売る。', translation: "He sells fruit.", username: 'atmarksharp', license: 'CC BY 2.0 FR'),
  ],
  'じゃ': [
    TatoebaSentence(id: 752229, text: 'じゃ。', translation: "See ya!", username: 'modelqueen13', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 215732, text: 'じゃあ何？', translation: "Then what?", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 778284, text: 'じゃあね！', translation: "I'll see you later.", username: 'kenken', license: 'CC BY 2.0 FR'),
  ],
  'たくさん': [
    TatoebaSentence(id: 179738, text: '金はたくさんある。', translation: "There is a lot of money.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12101354, text: '人がたくさんいた。', translation: "There were lots of people.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 203744, text: 'たくさん欲しい。', translation: "I want a lot.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '冷蔵庫': [
    TatoebaSentence(id: 10059087, text: '冷蔵庫に入ってるよ。', translation: "It's in the fridge.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8040014, text: '冷蔵庫に牛乳がない。', translation: "There isn't any milk in the refrigerator.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12462062, text: '冷蔵庫が壊れた。', translation: "Our fridge broke.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '椅子': [
    TatoebaSentence(id: 3191805, text: 'それは椅子ですか。', translation: "Is it a chair?", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 630321, text: '彼は椅子に座った。', translation: "He sat in the chair.", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7462000, text: 'この椅子大好き。', translation: "I love this chair.", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  '大勢': [
    TatoebaSentence(id: 1160459, text: '公園には大勢の人がいた。', translation: "There were a lot of people in the park.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9550210, text: '同僚なら大勢いるよ。', translation: "I have many colleagues.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 213674, text: 'そこには大勢の人がいた。', translation: "There was a large crowd there.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '留学生': [
    TatoebaSentence(id: 2412266, text: '留学生の方ですか？', translation: "Are you an exchange student?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901871, text: 'この学校は留学生が多いです。', translation: "There are many exchange students in this school.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10984928, text: '来月中国から留学生が来ます。', translation: "We have a foreign student coming from China next month.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '牛肉': [
    TatoebaSentence(id: 9192045, text: '牛肉は高い。', translation: "Beef is expensive.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 182303, text: '牛肉にしてください。', translation: "Beef, please.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11178742, text: '何よりも牛肉が好き。', translation: "I like beef more than anything.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'バス': [
    TatoebaSentence(id: 6828232, text: 'バスに乗ります。', translation: "I take a bus.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 198175, text: 'バスに乗りましょう。', translation: "Let's get on the bus.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 150339, text: '次のバスに乗ります。', translation: "I'll take the next bus.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '鳥': [
    TatoebaSentence(id: 125778, text: '鳥は飛ぶ。', translation: "Birds fly.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12462048, text: '鳥が飛んでる。', translation: "The bird is flying.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8732923, text: 'あれは鳥なの？', translation: "Is that a bird?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '先週': [
    TatoebaSentence(id: 155474, text: '先週彼に会いました。', translation: "I saw him last week.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10759903, text: '先週、トムを見たよ。', translation: "I saw Tom last week.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10570974, text: '先週は雪でした。', translation: "It snowed last week.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '橋': [
    TatoebaSentence(id: 1283104, text: 'そこに橋があった。', translation: "There was a bridge there.", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5390444, text: '橋の上に犬がいる。', translation: "There is a dog on the bridge.", username: 'Yakuwari', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 180119, text: '橋は修理中です。', translation: "The bridge is being repaired.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '四つ': [
    TatoebaSentence(id: 142870, text: '正方形には四つの辺がある。', translation: "A square has four sides.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 190235, text: '一年には四つの季節がある。', translation: "There are four seasons in a year.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10746415, text: '見て！四つ葉！', translation: "Look! A four-leafed clover!", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '古い': [
    TatoebaSentence(id: 14014941, text: '古い。', translation: "Old.", username: 'kris514', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4562504, text: 'これは古い本です。', translation: "This is an old book.", username: 'Kiraness', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 163877, text: '私の机は古い。', translation: "My desk is old.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '明るい': [
    TatoebaSentence(id: 1780144, text: '月は明るい。', translation: "The moon is bright.", username: 'Bah_Dure', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4211968, text: 'すごく明るい。', translation: "It's very bright.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 114448, text: '彼はいつも明るい。', translation: "He is always cheerful.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'ベッド': [
    TatoebaSentence(id: 11041833, text: 'ベッドの下よ。', translation: "It's under the bed.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3496845, text: 'ベッドを整えて。', translation: "Make your bed.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12703172, text: 'ベッドが気持ちいい。', translation: "The bed is comfortable.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '茶色': [
    TatoebaSentence(id: 10335765, text: 'トムの犬は茶色です。', translation: "Tom's dog is brown.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 982253, text: 'その猫は茶色です。', translation: "That cat is brown.", username: 'Arraroak', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 117753, text: '彼の靴は茶色だ。', translation: "His shoes are brown.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '池': [
    TatoebaSentence(id: 207853, text: 'その池はとても深い。', translation: "The pond is very deep.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10032757, text: 'この池は浅いです。', translation: "This pond is shallow.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7298710, text: '池が凍ってるよ。', translation: "The pond is frozen.", username: 'Mari_Taguchi', license: 'CC BY 2.0 FR'),
  ],

  // JLPT N5 Vocabulary continued (words 301-450 of the set) - again only
  // the words not already covered above.
  '来週': [
    TatoebaSentence(id: 1130332, text: 'また来週。', translation: "See you next week!", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8764341, text: '来週来るの？', translation: "Are you coming next week?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 516512, text: '来週戻ってくる。', translation: "I will come back next week.", username: 'kyleadrian10', license: 'CC BY 2.0 FR'),
  ],
  '大使館': [
    TatoebaSentence(id: 122209, text: '日本大使館はどこにありますか。', translation: "Where is the Japanese Embassy?", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10903698, text: '私は明日大使館へ行きます。', translation: "I'm going to the embassy tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2418677, text: 'オランダ大使館はどこですか？', translation: "Where is the Dutch embassy?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '警官': [
    TatoebaSentence(id: 2560042, text: '私は警官だ。', translation: "I'm a policeman.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8875313, text: 'トムは警官だよ。', translation: "Tom is a police officer.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 215438, text: 'ジョンは警官になった。', translation: "John became a policeman.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '散歩': [
    TatoebaSentence(id: 11455288, text: '散歩してくる。', translation: "I'll go for a walk.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 169326, text: '散歩をした。', translation: "I took a walk.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8649697, text: '散歩に行きたい？', translation: "Do you want to take a walk?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '漢字': [
    TatoebaSentence(id: 6828180, text: '漢字を書きます。', translation: "I write kanji.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10903672, text: '私は漢字が書けます。', translation: "I can write kanji.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11199160, text: '漢字の勉強をしてます。', translation: "I'm studying hanzi.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '二': [
    TatoebaSentence(id: 3496751, text: 'いま二時半。', translation: "It's 2:30 now.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 930200, text: '十二は偶数だ。', translation: "Twelve is an even number.", username: 'ryanwhiting', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10590373, text: '二列になって。', translation: "Form two lines.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '弟': [
    TatoebaSentence(id: 10012748, text: '太郎の弟だよ。', translation: "He's Taro's younger brother.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11760810, text: '弟さんはどこ？', translation: "Where's your little brother?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9486032, text: '弟の名前は？', translation: "What's your younger brother's name?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '屋': [
    TatoebaSentence(id: 2257028, text: '玉屋！鍵屋！', translation: "Jeweler! Locksmith!", username: 'archer_root', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 79884, text: '餅は餅屋。', translation: "Every man for his own trade.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 170962, text: '紺屋の白袴。', translation: "Shoemakers' children go barefoot.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '三': [
    TatoebaSentence(id: 1853758, text: '三時十分です。', translation: "It's 3:10.", username: 'Kamelio', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3468493, text: '男が三人いた。', translation: "There were three men.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11358720, text: '三月が終わる。', translation: "March is over.", username: 'cia_UnitedStatesNa13', license: 'CC BY 2.0 FR'),
  ],
  'ポケット': [
    TatoebaSentence(id: 9308415, text: 'ポケットを確認して。', translation: "Check your pockets.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9292200, text: 'ポケットに何入ってるの？', translation: "What do you have in your pocket?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9308449, text: '君のポケットの中だよ。', translation: "It's in your pocket.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '方': [
    TatoebaSentence(id: 11576569, text: 'どんな方なの？', translation: "What is he like?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10714063, text: '両方要るよ。', translation: "We need both.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9246462, text: '行き方わかる？', translation: "Do you know how to get there?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '物': [
    TatoebaSentence(id: 82540, text: '忘れ物ない？', translation: "Do you have everything?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 83829, text: '物は試し。', translation: "You'll never know unless you try.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11264687, text: '本物はどっち？', translation: "Which is the real one?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '辞書': [
    TatoebaSentence(id: 221509, text: 'この辞書は高い。', translation: "This dictionary is expensive.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1700215, text: 'Tatoebaは辞書だ。', translation: "Tatoeba is a dictionary.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12160583, text: '辞書持ってる？', translation: "Do you have a dictionary?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '荷物': [
    TatoebaSentence(id: 12074612, text: '荷物が届いた。', translation: "A package has arrived.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 233414, text: '荷物を運びましょうか？', translation: "Shall I carry your baggage?", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 186547, text: '荷物は何個ですか。', translation: "How many bags do you have?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '五': [
    TatoebaSentence(id: 90182, text: '彼女は五歳です。', translation: "She is five years old.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8598725, text: '五ドルある？', translation: "Do you have five dollars?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 79043, text: '夕方の五時です。', translation: "It's five in the evening.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '先': [
    TatoebaSentence(id: 12622786, text: '私が先に行くよ！', translation: "I'm going first!", username: 'FEN1X64', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10906684, text: 'カネが先だ。', translation: "Money up front.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11571063, text: '先手必勝だよ。', translation: "You have to strike first.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '晴れ': [
    TatoebaSentence(id: 171566, text: '今日は晴れだ。', translation: "It is sunny today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12412346, text: '明日は晴れよ。', translation: "It will be sunny tomorrow.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 179482, text: '空が晴れた。', translation: "The sky has become clear.", username: 'wat', license: 'CC BY 2.0 FR'),
  ],
  '一昨年': [
    TatoebaSentence(id: 10899771, text: '私は一昨年この山に登りました。', translation: "I climbed this mountain the year before last.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901474, text: '一昨年、オーストラリアに越してきました。', translation: "I moved to Australia the year before last.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901472, text: '一昨年、ボストンに越してきたんだ。', translation: "I moved to Boston the year before last.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '薬': [
    TatoebaSentence(id: 11825855, text: '薬は苦い。', translation: "The medicine is bitter.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11998683, text: '薬の時間だ。', translation: "It's time to take my pills.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2932768, text: '薬を買ったの？', translation: "Did you buy the medicine?", username: 'togu', license: 'CC BY 2.0 FR'),
  ],
  '万': [
    TatoebaSentence(id: 9049823, text: '一万円貸してくれない？', translation: "Can you lend me 10,000 yen?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901783, text: 'このコートは一万円です。', translation: "This coat is ten thousand yen.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 221605, text: 'この時計は一万円だった。', translation: "This watch cost me ten thousand yen.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '低い': [
    TatoebaSentence(id: 2349246, text: '私はとても背が低い。', translation: "I'm very short.", username: 'hutian', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901733, text: 'この山は低いです。', translation: "This is a low mountain.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9037416, text: '血圧が低いんだ。', translation: "I have low blood pressure.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '箸': [
    TatoebaSentence(id: 6828188, text: '箸で寿司を食べます。', translation: "I eat sushi with chopsticks.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9696344, text: '彼は箸が使えるよ。', translation: "He can use chopsticks.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10574154, text: '箸の持ち方が分かりません。', translation: "I don't understand the way to hold chopsticks.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '走る': [
    TatoebaSentence(id: 102792, text: '彼は走る。', translation: "He runs.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 155348, text: '私は走る。', translation: "I run.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 224594, text: 'ここでは走るな。', translation: "Don't run here.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '白い': [
    TatoebaSentence(id: 13976230, text: 'その本は白い。', translation: "The book is white.", username: 'HAGNi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1504570, text: 'ケンの犬は白い。', translation: "Ken's dog is white.", username: 'verbum', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 738246, text: 'この犬は白いです。', translation: "This dog is white.", username: 'DeSha', license: 'CC BY 2.0 FR'),
  ],
  '押す': [
    TatoebaSentence(id: 9101634, text: '押す！', translation: "Push!", username: 'tontonton', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10733637, text: 'ボタンを押す。', translation: "Press the button.", username: 'megamanenm', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3488278, text: '押すなよ。', translation: "Don't push.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '郵便局': [
    TatoebaSentence(id: 79171, text: '郵便局はどこですか。', translation: "Where is the post office?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8771777, text: '郵便局に行くの？', translation: "Are you going to the post office?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11505782, text: '郵便局はすぐ隣です。', translation: "The post office is just next door.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '嫌': [
    TatoebaSentence(id: 175405, text: '嫌だ！', translation: "No!", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9614904, text: 'もう嫌だ！', translation: "No more!", username: 'Sim5634', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11108097, text: '嫌な感じ。', translation: "I don't like this feeling.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '五つ': [
    TatoebaSentence(id: 349891, text: '一つ、二つ、三つ、四つ、五つ、六つ、七つ、八つ、九つ、十。', translation: "One, two, three, four, five, six, seven, eight, nine, ten.", username: 'human600', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3468523, text: 'この箱にはりんごが五つ入っている。', translation: "This box contains five apples.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 564149, text: '五つばかりの子供が自転車に轢かれたんですよ。', translation: "A child of just five was hit by a bicycle.", username: 'Scott', license: 'CC BY 2.0 FR'),
  ],
  '下手': [
    TatoebaSentence(id: 109798, text: '彼は運転が下手だ。', translation: "He is a bad driver.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10189292, text: '僕、絵が下手なんだ。', translation: "I am poor at drawing.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 159444, text: '私はテニスが下手だ。', translation: "I am poor at tennis.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '浴びる': [
    TatoebaSentence(id: 8468049, text: 'シャワーを浴びる。', translation: "I'll take a shower.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10298771, text: 'シャワー浴びるの？', translation: "Are you going to shower?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11563144, text: '朝シャワーを浴びる方がいいな。', translation: "I prefer to shower in the morning.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'いつも': [
    TatoebaSentence(id: 14014943, text: 'いつも。', translation: "Always.", username: 'kris514', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9466572, text: 'いつもありがとう。', translation: "Thanks, as always.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8723018, text: 'いつも忙しいの？', translation: "Are you always busy?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '立派': [
    TatoebaSentence(id: 78272, text: '立派ですね。', translation: "It's magnificent.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1771484, text: '立派な家ですね。', translation: "What a beautiful house!", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99026, text: '彼は立派な紳士です。', translation: "He is a fine gentleman.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'コーヒー': [
    TatoebaSentence(id: 12310683, text: 'コーヒー買った？', translation: "Did you get coffee?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10630513, text: 'コーヒー、飲む？', translation: "Do you drink coffee?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1274165, text: 'コーヒーはどう？', translation: "Won't you have some coffee?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '切る': [
    TatoebaSentence(id: 638321, text: '塩漬けキャベツを細かく切る。', translation: "Chop the pickled cabbage finely.", username: 'blay_paul', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12164699, text: '玉ねぎを切ると涙が出るのよね。', translation: "My eyes water when I cut onions.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13894164, text: 'そろそろ髪を切る時期だな。', translation: "It's time to get a haircut.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '姉': [
    TatoebaSentence(id: 9432274, text: '姉はいない。', translation: "I don't have an older sister.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10880199, text: 'お姉さんのことよ。', translation: "It's about your sister.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10778223, text: '姉は大学生です。', translation: "My sister is in college.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ホテル': [
    TatoebaSentence(id: 3366884, text: '今、ホテル。', translation: "I'm at the hotel.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2441437, text: 'ホテルに戻ろう。', translation: "Let's go back to the hotel.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5348327, text: 'ホテルはどこですか。', translation: "Where is the hotel?", username: 'pekerappo', license: 'CC BY 2.0 FR'),
  ],
  '切手': [
    TatoebaSentence(id: 9329576, text: '趣味は切手収集です。', translation: "My hobby is collecting stamps.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10815068, text: '切手はどこで買える？', translation: "Where can I get stamps?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11641292, text: '切手を集めてるんだ。', translation: "I collect stamps.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '夏': [
    TatoebaSentence(id: 10801959, text: '夏だね。', translation: "It's summer.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 187256, text: '夏が来た。', translation: "Summer has come.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11138359, text: '夏が一番好き。', translation: "I like summer best.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '赤い': [
    TatoebaSentence(id: 183646, text: '顔が赤いよ。', translation: "Your face is red.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2656862, text: '私の車は赤い。', translation: "My car is red.", username: 'Hikaru', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10667328, text: 'リンゴは赤い。', translation: "Apples are red.", username: 'YT', license: 'CC BY 2.0 FR'),
  ],
  '着る': [
    TatoebaSentence(id: 126602, text: '着る物がないの。', translation: "I don't have a thing to wear.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9134239, text: '冬にはコートを着るんだよ。', translation: "I wear an overcoat in the winter.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 212865, text: 'そのドレスを着ると素敵よ。', translation: "You look nice in that dress.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '祖父': [
    TatoebaSentence(id: 10763900, text: '私の祖父です。', translation: "This is my grandfather.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 163171, text: '祖父は散歩が好きです。', translation: "My grandfather likes to walk.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 163162, text: '私の祖父は長生きだった。', translation: "My grandfather lived a long life.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '隣': [
    TatoebaSentence(id: 8553951, text: '隣に座って。', translation: "Come sit by my side.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10503891, text: 'トムはお隣さんです。', translation: "Tom is our neighbor.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1537785, text: '銀行は郵便局の隣です。', translation: "The bank is next to the post office.", username: 'Scott', license: 'CC BY 2.0 FR'),
  ],
  '山': [
    TatoebaSentence(id: 156658, text: '私は山にいく。', translation: "I go to the mountain.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12296735, text: 'あの山は高いね。', translation: "That mountain is high.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8768433, text: '富士山は美しい。', translation: "Mount Fuji is beautiful.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '熱い': [
    TatoebaSentence(id: 8688654, text: '熱い？', translation: "Is it hot?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901746, text: 'この紅茶は熱いです。', translation: "This tea is hot.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11142917, text: '熱いから気をつけて。', translation: "Be careful. It's hot.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '映画館': [
    TatoebaSentence(id: 13236497, text: '映画館に行きましょう。', translation: "Let's go to the cinema.", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3850777, text: '映画館は駅から近いの？', translation: "Is the movie theater near the station?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12143064, text: '映画館で働いてます。', translation: "I work at a movie theater.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '牛乳': [
    TatoebaSentence(id: 13011264, text: '牛乳を飲んだ。', translation: "I drank milk.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9701215, text: '牛乳はどこだろう？', translation: "Where's the milk?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 182295, text: '牛乳が腐った。', translation: "The milk has gone bad.", username: 'wat', license: 'CC BY 2.0 FR'),
  ],
  'いくつ': [
    TatoebaSentence(id: 12890016, text: 'いくつですか？', translation: "How old are you?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8160498, text: '卵いくつ買った？', translation: "How many eggs did you buy?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8985120, text: 'いくつ残ってる？', translation: "How many are left?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '風邪': [
    TatoebaSentence(id: 1836391, text: '風邪ひいた。', translation: "I have caught a cold.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 83981, text: '風邪ですね。', translation: "It's just a cold.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12161027, text: '風邪引くよ。', translation: "You'll catch a cold.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'かける': [
    TatoebaSentence(id: 108707, text: '彼は眼鏡をかけている。', translation: "He is wearing glasses.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5903453, text: '時計は壁に掛ける。', translation: "Hang a clock on the wall.", username: 'Catamenia321', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 100073, text: '彼は母の誕生日には必ず電話をかける。', translation: "He never fails to call his mother on her birthday.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '鼻': [
    TatoebaSentence(id: 146304, text: '象は鼻が長い。', translation: "An elephant has a long nose.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9453681, text: '鼻が冷たい。', translation: "My nose is cold.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8649639, text: '鼻をかんで。', translation: "Blow your nose.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '交差点': [
    TatoebaSentence(id: 10166377, text: 'この交差点の名前は何でしょう？', translation: "What's the name of this intersection?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4147403, text: '次の交差点を右に曲がってください。', translation: "Turn right at the next intersection.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1502280, text: '交差点で事故があった。', translation: "There was an accident at the intersection.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '砂糖': [
    TatoebaSentence(id: 739216, text: '砂糖がない。', translation: "We have no sugar.", username: 'DeSha', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 170881, text: '砂糖は水に溶ける。', translation: "Sugar dissolves in water.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1485489, text: '砂糖はいらないよ。', translation: "I don't want any sugar.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
  ],
  '上着': [
    TatoebaSentence(id: 103995, text: '彼は上着を脱いだ。', translation: "He took off his coat.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 145376, text: '新しい上着をもらった。', translation: "I was given a new jacket.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11563363, text: 'あなたの上着はどこ？', translation: "Where's your jacket?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '黒い': [
    TatoebaSentence(id: 9043986, text: '黒いのが私のよ。', translation: "The black one is mine.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5845176, text: 'この車は黒い。', translation: "This car is black.", username: 'joejames', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2684263, text: 'カラスは黒い。', translation: "Crows are black.", username: 'cogas', license: 'CC BY 2.0 FR'),
  ],
  '歯': [
    TatoebaSentence(id: 11052195, text: '歯は32本です。', translation: "We have thirty-two teeth.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 150975, text: '歯が痛い。', translation: "I've got a toothache.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9738167, text: '歯磨きはしたの？', translation: "Did you brush your teeth?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '卵': [
    TatoebaSentence(id: 125772, text: '鳥は卵を産む。', translation: "Birds lay eggs.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 78489, text: '卵は嫌いです。', translation: "I don't care for eggs.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11733648, text: '卵を買ったんだ。', translation: "I bought some eggs.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '向こう': [
    TatoebaSentence(id: 173836, text: '向こうへ行け！', translation: "Get away!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 173845, text: '向こうに白い塔が見えます。', translation: "You can see a white tower over there.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901769, text: '病院は駅の向こうです。', translation: "The hospital is on the other side of the station.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '塩': [
    TatoebaSentence(id: 1678503, text: '塩ください。', translation: "The salt, if you please.", username: 'aka_aj', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 467328, text: 'もう塩がない。', translation: "There is no salt left.", username: 'Namikaze', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 227398, text: 'お塩とって。', translation: "Pass me the salt.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'パン': [
    TatoebaSentence(id: 8026857, text: 'パンを焼きますか？', translation: "Do you bake bread?", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6458286, text: '猫はパンを食べる。', translation: "The cat eats bread.", username: 'LeeSooHa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1510008, text: 'パンを買いにいく。', translation: "I'll go buy some bread.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
  ],
  '寝る': [
    TatoebaSentence(id: 6828218, text: '猫が寝る。', translation: "A cat sleeps.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 139770, text: '寝るぞ！', translation: "I'm going to bed.", username: 'fcbond', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 235973, text: '１１時に寝る。', translation: "I go to bed at eleven.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '廊下': [
    TatoebaSentence(id: 6828197, text: '廊下に箱がある。', translation: "There's a box in the hall.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13179752, text: '学校の廊下はいつもにぎやかだ。', translation: "The school corridors are always crowded.", username: 'Gardenia', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10984811, text: 'トイレは廊下の左側にあります。', translation: "The bathroom is on the left side of the hallway.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '渡す': [
    TatoebaSentence(id: 1866514, text: '君に渡す物がある。', translation: "I have something to give you.", username: 'Unaden', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1795038, text: '私は夕方君に指輪を渡すつもりだ。', translation: "I'm going to give you the ring this evening.", username: 'Akatsuki', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13894116, text: '最終的に、彼を警察に引き渡すことにした。', translation: "We finally decided to hand him over to the cops.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '紅茶': [
    TatoebaSentence(id: 8875104, text: '紅茶はいかが？', translation: "How about some tea?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 157132, text: '紅茶を一杯飲みたい。', translation: "I want to drink a cup of tea.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8576120, text: '紅茶をください。', translation: "Tea, please.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'パーティー': [
    TatoebaSentence(id: 8793343, text: 'そのパーティーにいたの？', translation: "Were you at the party?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9755697, text: 'パーティーはどうだった？', translation: "How did you like the party?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11604026, text: 'パーティーは今日よ。', translation: "The party's today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '降りる': [
    TatoebaSentence(id: 9793312, text: '終点で降りる。', translation: "We'll get off at the last station.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13476186, text: 'どの駅で降りるの？', translation: "Which stop are you getting off at?", username: 'ninefi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 156346, text: '私は次の駅で降りるつもりです。', translation: "I am getting off at the next station.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '風呂': [
    TatoebaSentence(id: 226694, text: 'お風呂沸いてる？', translation: "Is the bath ready?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11763476, text: 'お風呂の時間です。', translation: "It's time to take a bath.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12146793, text: '毎日お風呂に入るよ。', translation: "I bathe every day.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '喫茶店': [
    TatoebaSentence(id: 222390, text: 'この喫茶店、居心地がいいな。', translation: "This coffee shop is cozy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1127354, text: 'あそこに喫茶店があります。', translation: "There is a coffee shop over there.", username: 'negichan', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10550428, text: '喫茶店に行きたい？', translation: "Do you want to go to a coffee shop?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '毎朝': [
    TatoebaSentence(id: 10953992, text: '毎朝六時に起きます。', translation: "I get up at six every morning.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 84355, text: '父は毎朝散歩する。', translation: "My father takes a walk every morning.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9528527, text: '毎朝、走ってるよ。', translation: "I jog every morning.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '歌う': [
    TatoebaSentence(id: 1151661, text: '私は今歌う。', translation: "I sing now.", username: 'FiRez', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10550166, text: '一緒に歌おう。', translation: "Let's sing together.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 164891, text: '私と一緒に歌いましょう。', translation: "Sing a song with me.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '風': [
    TatoebaSentence(id: 670057, text: '風が吹く。', translation: "The wind blows.", username: 'szaby78', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8688662, text: '風は強い？', translation: "Is it windy?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11825726, text: '風って、何色？', translation: "What color is the wind?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '借りる': [
    TatoebaSentence(id: 179699, text: '金を借りるのも貸すのも嫌だ。', translation: "I don't want to lend or borrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8658010, text: '自転車を借りるのに、いくらかかりますか？', translation: "How much does it cost to rent a bicycle?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 227221, text: 'お金を借りる事は私の主義に反する。', translation: "It is against my principles to borrow money.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '宿題': [
    TatoebaSentence(id: 4260182, text: '宿題終わった？', translation: "Have you finished your homework?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1202341, text: '宿題やった？', translation: "Did you do your homework?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9077181, text: '宿題してるよ。', translation: "I'm doing my homework.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '封筒': [
    TatoebaSentence(id: 84069, text: '封筒をください。', translation: "I need an envelope.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1278062, text: '封筒がいる。', translation: "I need an envelope.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11126881, text: '封筒を開けました。', translation: "I opened the envelope.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '飲み物': [
    TatoebaSentence(id: 14011189, text: '飲み物持ってきて。', translation: "Bring something to drink.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 227408, text: 'お飲み物はいかが？', translation: "Would you like something to drink?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8588531, text: '飲み物、ありがとう。', translation: "Thanks for the drink.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '細い': [
    TatoebaSentence(id: 10085318, text: '心細いの。', translation: "I'm lonely.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9124273, text: 'その通りはとても細いんだ。', translation: "The street is very narrow.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10536837, text: 'トムは歳の割に細いです。', translation: "Tom is small for his age.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '昨夜': [
    TatoebaSentence(id: 8728875, text: '昨夜、酔ってた？', translation: "Were you drunk last night?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12418818, text: '昨夜、見たわ。', translation: "I saw it last night.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 169640, text: '昨夜は暑かった。', translation: "It was hot last night.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '晩': [
    TatoebaSentence(id: 12698696, text: '明日の晩はどう？', translation: "What about tomorrow night?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8688639, text: '晩ご飯できた？', translation: "Is dinner ready?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 171215, text: '今晩暇かな？', translation: "Are you free tonight?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '待つ': [
    TatoebaSentence(id: 11566636, text: '外で待つつもりよ。', translation: "I'm going to wait outside.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10330140, text: '待つのは嫌いだ。', translation: "I don't like waiting.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8572349, text: '門の前で待つよ。', translation: "I'll wait for you at the front gate.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '今朝': [
    TatoebaSentence(id: 8651862, text: '今朝の虹みた？', translation: "Did you see the rainbow this morning?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 172280, text: '今朝は何をしたの？', translation: "What did you do this morning?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 172252, text: '今朝は特に寒い。', translation: "It is especially cold this morning.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '鉛筆': [
    TatoebaSentence(id: 6828204, text: 'これは鉛筆。', translation: "This is a pencil.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3030039, text: '誰か鉛筆持ってる？', translation: "Do any of you have a pencil?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3114655, text: 'この鉛筆、誰の？', translation: "Whose pencil is this?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '傘': [
    TatoebaSentence(id: 4769896, text: 'この傘誰の？', translation: "Whose umbrella is this?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8582297, text: '傘を買った。', translation: "I bought an umbrella.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2269959, text: '私の傘です。', translation: "That's my umbrella.", username: 'rockelle', license: 'CC BY 2.0 FR'),
  ],
  '辺': [
    TatoebaSentence(id: 8758021, text: 'その辺に誰かいる？', translation: "Is there anyone else around?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3623488, text: 'この辺に住んでるの？', translation: "Do you live near here?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9972244, text: 'この辺は寒いよ。', translation: "It's cold around here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '火曜日': [
    TatoebaSentence(id: 11332317, text: '今日は火曜日です。', translation: "Today is Tuesday.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 186643, text: '火曜日はお暇ですか。', translation: "Are you free on Tuesday?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1208127, text: '火曜日に会いましょう。', translation: "Let's meet on Tuesday.", username: 'deparuma', license: 'CC BY 2.0 FR'),
  ],
  '背広': [
    TatoebaSentence(id: 155725, text: '私は新しい背広を買った。', translation: "I bought a new suit of clothes.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 74070, text: '彼はくたくたの背広を着ていた。', translation: "He was wearing a threadbare suit.", username: 'fcbond', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 237456, text: '彼のネクタイは背広によく合っている。', translation: "His tie corresponds well with his suit.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '七つ': [
    TatoebaSentence(id: 13535398, text: '七つ？', translation: "Seven?", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 349891, text: '一つ、二つ、三つ、四つ、五つ、六つ、七つ、八つ、九つ、十。', translation: "One, two, three, four, five, six, seven, eight, nine, ten.", username: 'human600', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9718152, text: '桃子は、おはじきを「一つ、二つ、三つ、四つ、五つ、六つ、七つ、八つ、九つ、十」まで数えると黙り込んでしまいました。お母さんが「十一、十二、十三」と続けると嬉しそうに「十四、十五、十六」と数え続けました。', translation: "Momoko counted the marbles: \"One, two, three, four, five, six, seven, eight, nine, ten\" and then went silent. When her mother continued with \"eleven, twelve, thirteen,\" she happily picked up with \"fourteen, fifteen, sixteen.\"", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '赤': [
    TatoebaSentence(id: 11049469, text: '赤の方が好き。', translation: "I prefer red.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13901006, text: '犬の首輪は赤だ。', translation: "The dog's collar is red.", username: 'kylewii', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 183646, text: '顔が赤いよ。', translation: "Your face is red.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '甘い': [
    TatoebaSentence(id: 223018, text: 'このりんごは甘い。', translation: "This apple is sweet.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 124149, text: '桃は甘い。', translation: "Peaches taste sweet.", username: 'verbum', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3635288, text: '甘いものが食べたい。', translation: "I want something sweet to eat.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'カップ': [
    TatoebaSentence(id: 9448689, text: 'これはトムのカップだよ。', translation: "This is Tom's cup.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 226319, text: 'カップが割れた。', translation: "The cup broke.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3565420, text: '私のマグカップ取って。', translation: "Hand me my mug.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '薄い': [
    TatoebaSentence(id: 224899, text: 'コーヒーは薄いのが好きです。', translation: "I'd like my coffee weak.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 220205, text: 'この薄い本は私のです。', translation: "This thin book is mine.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2147109, text: '私の新しい電話は前のより薄い。', translation: "My new phone is thinner than my old phone.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  // 貼る (はる) didn't turn up many short/clean matches - these 3 are the
  // best genuine hits.
  '貼る': [
    TatoebaSentence(id: 13535074, text: '心に貼る。', translation: "It's close to your heart.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9073561, text: '私が出すの頼んでおいた手紙にさ、切手貼るの忘れないでよ。', translation: "Please don't forget to put stamps on the letters that I gave you to mail.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3480777, text: '日本の温泉に入湯が許されるよう、トムは小さな蜘蛛の刺青の上にバンドエイドを貼った。', translation: "Tom put a Band-Aid over his small tattoo of a spider so he would be allowed into a Japanese hot spring.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  'いろいろ': [
    TatoebaSentence(id: 114394, text: '彼はいろいろ知っている。', translation: "He knows lots.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10908693, text: '理由はいろいろある。', translation: "There are many reasons.", username: 'SomeHungryBois', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 224928, text: 'コーヒーにもいろいろある。', translation: "There are many kinds of coffee.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'カレンダー': [
    TatoebaSentence(id: 10989087, text: 'カレンダーはどこ？', translation: "Where is the calendar?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10926432, text: '机の上にカレンダーが置いてあります。', translation: "There's a calendar on the desk.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2860761, text: '私は壁にカレンダーを掛ける。', translation: "I hang the calendar on the wall.", username: 'Nekonari', license: 'CC BY 2.0 FR'),
  ],
  '誕生日': [
    TatoebaSentence(id: 2349399, text: '誕生日おめでとう。', translation: "Happy birthday!", username: 'hutian', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3073578, text: '誕生日いつ？', translation: "When is your birthday?", username: 'nnaffu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11571100, text: '誰の誕生日？', translation: "Whose birthday is it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '靴下': [
    TatoebaSentence(id: 2654934, text: 'トムは靴下を脱いだ。', translation: "Tom removed his socks.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11436376, text: '私の赤い靴下どこ？', translation: "Where are my red socks?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9696507, text: '靴下は脱ぎなさい。', translation: "Take off your socks.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '鶏肉': [
    TatoebaSentence(id: 709402, text: '僕は鶏肉が好きです。', translation: "I love chicken.", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 87832, text: '彼女は鶏肉を買った。', translation: "She bought chicken.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9934315, text: '私は鶏肉を食べたい。', translation: "I feel like chicken.", username: 'D0UG', license: 'CC BY 2.0 FR'),
  ],
  '始まる': [
    TatoebaSentence(id: 8858163, text: '始まる！', translation: "It begins!", username: 'moxy', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 184423, text: '学校は４月に始まる。', translation: "School begins in April.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 187440, text: '何時に始まるの？', translation: "What time does it start?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '太い': [
    TatoebaSentence(id: 10784290, text: 'トムは首が太いんだ。', translation: "Tom has a thick neck.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901745, text: 'このペンは太いです。', translation: "This pen is thick.", username: 'Kaede', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 188410, text: '俺、指が太いから、小さなキーボードじゃだめなんだよ。', translation: "I have chubby fingers, so I can't use a small keyboard.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'クラス': [
    TatoebaSentence(id: 10625629, text: 'どこのクラスなの？', translation: "Which class are you in?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4569333, text: 'クラスに友達いる？', translation: "Do you have friends in your class?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3642234, text: '新しいクラスはどう？', translation: "How is your new class?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '万年筆': [
    TatoebaSentence(id: 81091, text: '万年筆を持っていますか。', translation: "Do you have a fountain pen with you?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9257754, text: '新しい万年筆買ったんだ。', translation: "I bought a new fountain pen.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9257765, text: '万年筆で書くのが好きなんだ。', translation: "I like writing with a fountain pen.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '返す': [
    TatoebaSentence(id: 227236, text: 'お金は明日返すよ。', translation: "I'll give you back the money tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9182074, text: '図書館に本を返すの、忘れないでよ。', translation: "Don't forget to return the book to the library.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 219485, text: 'この本を返さないといけないんです。', translation: "I just have to drop this book off.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '切符': [
    TatoebaSentence(id: 13864877, text: 'あなたの切符よ。', translation: "Here's a ticket for you.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1256367, text: '切符持ってますか？', translation: "Do you have a ticket?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 992069, text: '帰りの切符は買ったの？', translation: "Did you buy a return ticket?", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '忙しい': [
    TatoebaSentence(id: 152827, text: '私は忙しい。', translation: "I'm busy.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8845007, text: 'まだ忙しい？', translation: "Are you still busy?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2226724, text: '少し忙しい。', translation: "I'm a little busy.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'トイレ': [
    TatoebaSentence(id: 3553339, text: 'ここがトイレです。', translation: "This is the bathroom.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10914910, text: 'トイレ行ってくる。', translation: "I'm going to the restroom.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11906435, text: 'トイレはどこですか？', translation: "Where is the bathroom?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '丸い': [
    TatoebaSentence(id: 126969, text: '地球は丸い。', translation: "The earth is round.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 196476, text: 'ボールは丸い。', translation: "Balls are round.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 77791, text: '林檎の形は丸い。', translation: "An apple is round in shape.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '若い': [
    TatoebaSentence(id: 81865, text: '僕は若い。', translation: "I'm young.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 110825, text: '彼はまだ若い。', translation: "He is still young.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2249894, text: '彼は気が若い。', translation: "He is young at heart.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'スカート': [
    TatoebaSentence(id: 10155998, text: 'このスカート、安いわね。', translation: "This skirt is cheap.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11351732, text: 'そのスカートはどこで買ったの？', translation: "Where did you buy that skirt?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 889775, text: 'そのスカート、短すぎない？', translation: "Isn't that skirt too short?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '重い': [
    TatoebaSentence(id: 219601, text: 'この本は重い。', translation: "This book is heavy.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7577243, text: 'トムは重い。', translation: "Tom is heavy.", username: 'Kisu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11588970, text: '重いですよ。', translation: "It's heavy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ノート': [
    TatoebaSentence(id: 10901827, text: 'これは私のノートです。', translation: "This is my notebook.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 231281, text: 'あのノートは誰のですか？', translation: "Whose notebook is that?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3631880, text: 'ノートを出しなさい。', translation: "Take out your notebooks.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'じゃあ': [
    TatoebaSentence(id: 215732, text: 'じゃあ何？', translation: "Then what?", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8942279, text: 'じゃあ、また。', translation: "Well, see you later.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 778284, text: 'じゃあね！', translation: "I'll see you later.", username: 'kenken', license: 'CC BY 2.0 FR'),
  ],
  '空': [
    TatoebaSentence(id: 179417, text: '空は青い。', translation: "The sky is blue.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 179482, text: '空が晴れた。', translation: "The sky has become clear.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11195064, text: '空を見てみろよ！', translation: "Look up there at the sky!", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  // 円い (まるい, "round") is almost entirely swamped by 円 ("yen") in the
  // corpus - this is the one genuine match.
  '円い': [
    TatoebaSentence(id: 1334916, text: '円い箱か？あんた正気か？', translation: "Round boxes? Are you nuts?", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
  ],
  '青い': [
    TatoebaSentence(id: 2397000, text: '海は青いです。', translation: "The sea is blue.", username: 'Hayabusa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1394283, text: '車が青い。', translation: "The car is blue.", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10059828, text: '花は青いです。', translation: "The flower is blue.", username: 'hansolo', license: 'CC BY 2.0 FR'),
  ],
  '近く': [
    TatoebaSentence(id: 12962650, text: 'トムは近くにいた。', translation: "Tom was nearby.", username: 'Inu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8748261, text: 'この近くにあるの？', translation: "Is it nearby?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 234969, text: '７時近くだ。', translation: "It is close to seven o'clock.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
  ],
  'わかる': [
    TatoebaSentence(id: 172754, text: '今にわかる。', translation: "You'll see.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10037930, text: '私が誰かわかる？', translation: "Do you know who I am?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10550170, text: '歌詞がわかる？', translation: "Do you know the lyrics?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '遊ぶ': [
    TatoebaSentence(id: 9550392, text: 'ここで遊ぶな。', translation: "Don't play here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10509279, text: '庭で遊ぶのが好きなんだ。', translation: "I like playing in the yard.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 125655, text: '通りで遊ぶと危険です。', translation: "It is dangerous to play in the street.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '叔父': [
    TatoebaSentence(id: 4292438, text: 'トムは私の叔父です。', translation: "Tom is my uncle.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 105789, text: '彼は私の叔父です。', translation: "He is my uncle.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10212496, text: '叔父は大金持ちです。', translation: "My uncle has a ton of money.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '本棚': [
    TatoebaSentence(id: 3465872, text: 'ジョンは本棚を組み立てた。', translation: "John built a bookcase.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1005840, text: '彼は本棚から本を１冊取った。', translation: "He took a book from the bookshelf.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 81575, text: '本棚に英和辞典がありますか。', translation: "Is there an English-Japanese dictionary on the bookshelf?", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '撮る': [
    TatoebaSentence(id: 156158, text: '写真を撮るのが好きです。', translation: "I'm fond of taking pictures.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2199352, text: '写真を撮ることができますか。', translation: "Can you take a picture?", username: 'minatsou', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10565617, text: 'トムは写真を撮るのが好きだ。', translation: "Tom likes taking pictures.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '茶碗': [
    TatoebaSentence(id: 202391, text: 'テーブルの上に茶碗があります。', translation: "There is a cup on the table.", username: 'Kaede', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 509438, text: '彼は茶碗のふちを欠いた。', translation: "He chipped the edge of the tea cup.", username: 'xtofu80', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13714041, text: '湯飲みにはお茶を入れてお茶碗にはご飯をよそいます。', translation: "We pour tea in a teacup and serve rice in a rice bowl.", username: 'GreySquirrel', license: 'CC BY 2.0 FR'),
  ],
  '暇': [
    TatoebaSentence(id: 158004, text: '私は暇だ。', translation: "I'm free.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2752686, text: 'いま暇？', translation: "Are you free now?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1115084, text: '今暇です。', translation: "I'm free now.", username: 'riccioberto', license: 'CC BY 2.0 FR'),
  ],

  // JLPT N5 Vocabulary continued (words 451-600 of the set) - again only
  // the words not already covered above.
  '毎晩': [
    TatoebaSentence(id: 10198765, text: '毎晩ここにいるよ。', translation: "I'm here every evening.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 81225, text: '毎晩電話するよ。', translation: "I'll give you a ring every night.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 152681, text: '私は毎晩家にいます。', translation: "I am at home every evening.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '豚肉': [
    TatoebaSentence(id: 123261, text: '豚肉は私には合わない。', translation: "Pork doesn't agree with me.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8760856, text: 'これは牛肉？それとも豚肉？', translation: "Is this beef or pork?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10903695, text: '私は豚肉が食べられません。', translation: "I can't eat pork.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '辛い': [
    TatoebaSentence(id: 8688655, text: '辛い？', translation: "Is it hot?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9453628, text: 'この梅干し、塩辛いね。', translation: "This umeboshi tastes really salty.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11140765, text: '気をつけて。辛いよ。', translation: "Be careful. It's spicy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'どちら': [
    TatoebaSentence(id: 1326963, text: 'どちらさまですか？', translation: "May I ask who you are?", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10914888, text: '国はどちらですか。', translation: "Which country are you from?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 200791, text: 'どちらでもどうぞ。', translation: "Take whichever one you like.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '休む': [
    TatoebaSentence(id: 108870, text: '彼は学校をよく休む。', translation: "He is often absent from school.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 108496, text: '彼は休む必要があった。', translation: "He needed to rest.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11168193, text: '休むのが大好き。', translation: "I love resting.", username: 'janTuki', license: 'CC BY 2.0 FR'),
  ],
  'レストラン': [
    TatoebaSentence(id: 5070677, text: 'レストランはどこですか？', translation: "Where is the restaurant?", username: '999yudai', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11216082, text: 'あのレストランは好き。', translation: "I like that restaurant.", username: 'DJ_Saidez', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2385303, text: 'このレストランは高すぎる。', translation: "This restaurant's too expensive.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'テープ': [
    TatoebaSentence(id: 226391, text: 'カセットテープを買うつもりです。', translation: "I will buy cassette tapes.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11457423, text: 'このテープ、聞いてみようよ。', translation: "Let's listen to this cassette.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 80389, text: '明日までこのテープを持ってていいよ。', translation: "You can keep this tape until tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '再来年': [
    TatoebaSentence(id: 10982399, text: '再来年、国へ帰ります。', translation: "I'm returning to my home country the year after next.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10682237, text: 'うちの息子は、再来年二十歳になります。', translation: "Our son will be 20 years old in two years.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 140720, text: '祖父は、再来年引退する予定です。', translation: "My grandfather is planning to retire the year after next.", username: 'JGGG', license: 'CC BY 2.0 FR'),
  ],
  // しょうゆ (soy sauce) had no usable kana hits - these use the 醤油
  // kanji spelling of the same word.
  'しょうゆ': [
    TatoebaSentence(id: 2711862, text: 'トム、そこの醤油取って。', translation: "Tom, please pass me that soy sauce.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10135808, text: '寿司に醤油なんてつけないわ。', translation: "I never dip my sushi in soy sauce.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11933176, text: 'マヨネーズと醤油を買わなきゃ。', translation: "I need to buy some mayonnaise and soy sauce.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ドア': [
    TatoebaSentence(id: 1509094, text: 'ドアを閉めて！', translation: "Shut the door.", username: 'CHNO', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 201801, text: 'ドアを開けて。', translation: "Open the door.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8888551, text: 'ドアを開けます。', translation: "I open the door.", username: 'mochico', license: 'CC BY 2.0 FR'),
  ],
  'フィルム': [
    TatoebaSentence(id: 1699684, text: 'フィルムが切れた。', translation: "My film has run out.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 223254, text: 'このフィルムを現像してもらえますか。', translation: "Can I have this film developed?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 226201, text: 'カラーフィルムを一本ください。', translation: "I want a roll of color film for prints.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'どうぞ': [
    TatoebaSentence(id: 8533908, text: 'どうぞ。', translation: "Please.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 198337, text: 'はいどうぞ。', translation: "Here it is.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10918319, text: 'はい、どうぞ。', translation: "Here you are.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'あっち': [
    TatoebaSentence(id: 7928643, text: 'あっちに座って。', translation: "Sit over there.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8980658, text: 'トムん家は、あっちだよ。', translation: "Tom's house is over there.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1296640, text: 'あっちへ行け！', translation: "Go away.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'ポスト': [
    TatoebaSentence(id: 196278, text: 'ポストはどこにありますか。', translation: "Where is the mailbox?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 110953, text: '彼はポストに手紙を入れた。', translation: "He dropped a letter into the mailbox.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9576743, text: 'この近くにポストはありますか？', translation: "Is there a mailbox near here?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '洗う': [
    TatoebaSentence(id: 8885672, text: 'お皿は洗うから。', translation: "I'm going to wash the dishes.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8997679, text: '毎日、髪の毛は洗うよ。', translation: "I wash my hair every day.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 141221, text: '洗う必要がある。', translation: "It needs washing.", username: 'kmt', license: 'CC BY 2.0 FR'),
  ],
  '九つ': [
    TatoebaSentence(id: 1856656, text: '新二は九つのココナッツを食べました。', translation: "Shinji ate nine coconuts.", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 349891, text: '一つ、二つ、三つ、四つ、五つ、六つ、七つ、八つ、九つ、十。', translation: "One, two, three, four, five, six, seven, eight, nine, ten.", username: 'human600', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9718152, text: '桃子は、おはじきを「一つ、二つ、三つ、四つ、五つ、六つ、七つ、八つ、九つ、十」まで数えると黙り込んでしまいました。お母さんが「十一、十二、十三」と続けると嬉しそうに「十四、十五、十六」と数え続けました。', translation: "Momoko counted the marbles: \"One, two, three, four, five, six, seven, eight, nine, ten\" and then went silent. When her mother continued with \"eleven, twelve, thirteen,\" she happily picked up with \"fourteen, fifteen, sixteen.\"", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '曇り': [
    TatoebaSentence(id: 171795, text: '今日は曇りです。', translation: "It's cloudy today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 123255, text: '曇りの日です。', translation: "It's a cloudy day.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 170020, text: '昨日は曇りだった。', translation: "It was cloudy yesterday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '三日': [
    TatoebaSentence(id: 13511301, text: '三日前だ。', translation: "That was three days ago.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1114590, text: '三日前、トムは去った。', translation: "Tom left three days ago.", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 595919, text: '蝶の寿命は三日です。', translation: "The lifetime of a butterfly is three days.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'あちら': [
    TatoebaSentence(id: 201727, text: 'トイレはあちらにあります。', translation: "The toilet is over there.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 234346, text: 'あちらに富士山が見えます。', translation: "We can see Mt. Fuji over there.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8845003, text: 'あちらの方は奥さんですか？', translation: "Is that your wife?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '消す': [
    TatoebaSentence(id: 4971651, text: 'ここの電気どうやって消すの？', translation: "How can I turn off this light?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 124838, text: '電気を消すのを忘れないで。', translation: "Don't forget to turn the light off.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 226397, text: 'ガスを消すのを忘れたわ。', translation: "I forgot to turn off the gas!", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '軽い': [
    TatoebaSentence(id: 971354, text: 'この椅子は軽い。', translation: "This chair is light.", username: 'thyc244', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2694261, text: 'トムは口が軽い。', translation: "Tom has a big mouth.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 176055, text: '軽い昼食をとりました。', translation: "I had a light lunch.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '東': [
    TatoebaSentence(id: 4562324, text: '東はどの方向なの？', translation: "What direction is east?", username: 'Kiraness', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13778774, text: '東京はどの国の首都？', translation: "Tokyo is the capital of which country?", username: 'ninefi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12593293, text: '東海岸出身です。', translation: "I'm from the East Coast.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '出かける': [
    TatoebaSentence(id: 8736594, text: '出かけるの？', translation: "Are you going out?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13536154, text: '何時に出かける？', translation: "What time are you leaving?", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 147802, text: '出かける時間よ。', translation: "It's time to go.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'どっち': [
    TatoebaSentence(id: 10669785, text: 'どっちに行く？', translation: "Which way will we go?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11264687, text: '本物はどっち？', translation: "Which is the real one?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13511287, text: 'どっちがいい？', translation: "Which do you like better?", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
  ],
  '灰皿': [
    TatoebaSentence(id: 185012, text: '灰皿を下さい。', translation: "I need an ashtray.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 185013, text: '灰皿を割ってしまいました。', translation: "I broke your ashtray.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2874638, text: '煙草を吸う人とキスをするのは灰皿を舐めるようなものだ。', translation: "Kissing a person who smokes is like licking an ashtray.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '冷たい': [
    TatoebaSentence(id: 8796822, text: '水は冷たい？', translation: "Is the water cold?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 77673, text: '冷たいなあ。', translation: "That's a bit cold.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 85392, text: '氷のように冷たい。', translation: "It's as cold as ice.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '曲がる': [
    TatoebaSentence(id: 184536, text: '角を曲がると、湖が見えてきた。', translation: "As we went around the corner, the lake came in sight.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 189916, text: '右に曲がると、白い塔が見えます。', translation: "Turning to the right, you will see a white tower.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11444719, text: '左に曲がると、白い建物があります。', translation: "If you turn to the left, you'll see a white building.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '泳ぐ': [
    TatoebaSentence(id: 9735094, text: '泳ぐのが大好きなんだ。', translation: "I love swimming.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10589678, text: '俺、泳ぐの速いんだ。', translation: "I can swim fast.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2620401, text: 'トムは泳ぐのが上手い。', translation: "Tom is able to swim well.", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
  ],
  '八百屋': [
    TatoebaSentence(id: 10903720, text: '果物や野菜は八百屋で買ってるよ。', translation: "I buy my fruits and vegetables at the greengrocer's.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10903729, text: '私は時々この八百屋で買い物をします。', translation: "I sometimes shop at this produce store.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 589579, text: '米屋や、八百屋に借金が出来て行った。', translation: "I built up some debts at the rice seller and at the greengrocer.", username: 'Scott', license: 'CC BY 2.0 FR'),
  ],
  'ラジオ': [
    TatoebaSentence(id: 218506, text: 'これはラジオですか。', translation: "Is this a radio?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 192599, text: 'ラジオをつけてくれ。', translation: "Turn on the radio.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 158618, text: 'ラジオで聞きました。', translation: "I heard it on the radio.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '降る': [
    TatoebaSentence(id: 468677, text: '雪が降る。', translation: "It's snowing.", username: 'Namikaze', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 190664, text: '１月は雪が降る。', translation: "We have snow in January.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 189727, text: '雨が降るそうだ。', translation: "They say it will rain.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '締める': [
    TatoebaSentence(id: 11655068, text: '必ずシートベルトを締めること。', translation: "Always fasten your seatbelt.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 198630, text: 'ネクタイを締める間、ちょっとじっとしてね。', translation: "Hold still a moment while I fix your tie.", username: 'Kaede', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10774889, text: '玄関の鍵を締めるのを忘れてしまった。', translation: "I forgot to lock the front door.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '要る': [
    TatoebaSentence(id: 3219284, text: '要る？', translation: "Want it?", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11076927, text: '金が要るんだ。', translation: "I need money.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9960398, text: '車が要るの？', translation: "Do you want a car?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  // 並ぶ didn't turn up many short/clean matches - these 3 are the best
  // genuine hits.
  '並ぶ': [
    TatoebaSentence(id: 4102651, text: '食欲は、睡眠欲・性欲と並ぶ人間の三大欲求の一つである。', translation: "Appetite is one of humankind's three primal needs, alongside sleep and sexual desire.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11110157, text: '激安の玉子を買うために行列に並ぶことにした。', translation: "I decided to wait in line to buy some super cheap eggs.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11056150, text: 'あの大企業のお膝元らしく巨大工場が立ち並ぶ。', translation: "There's a row of huge factories as though it were the seat of that large corporation.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '見せる': [
    TatoebaSentence(id: 183532, text: '喜怒哀楽を見せるな。', translation: "Don't let your feelings show.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 120317, text: '彼が姿を見せるまでここで待とう。', translation: "Let's wait here until he turns up.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2766189, text: '下着は隠すものではなく見せるものである。', translation: "Underwear is not meant to be hidden, but rather to be shown.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'かかる': [
    TatoebaSentence(id: 13065971, text: '最低でも1時間はかかる。', translation: "It'll take at least an hour.", username: 'Gardenia', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1200724, text: '体重が気にかかる。', translation: "I'm worried about my weight.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 182285, text: '裁判はお金がかかる。', translation: "Justice is expensive.", username: 'sugisaki', license: 'CC BY 2.0 FR'),
  ],
  '石けん': [
    TatoebaSentence(id: 142355, text: '石けんをください。', translation: "I need some soap.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 142357, text: '石けんで手を洗いなさい。', translation: "Wash your hands with soap.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 142358, text: '石けんが目にしみました。', translation: "The soap hurt my eyes.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '兄': [
    TatoebaSentence(id: 176635, text: '兄がいます。', translation: "I have an older brother.", username: 'Ianagisacos', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10129180, text: '兄を紹介します。', translation: "I'll introduce you to my brother.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11563492, text: '兄を探してます。', translation: "I am looking for my brother.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '起きる': [
    TatoebaSentence(id: 545842, text: '起きる時間だ。', translation: "It's time to get up.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 992952, text: '私は七時に起きる。', translation: "I get up at 7:00.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10726292, text: '明日何時に起きるの？', translation: "What time will you get up tomorrow?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'しかし': [
    TatoebaSentence(id: 216249, text: 'しかし、なぜ？', translation: "But why?", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 216308, text: 'しかし、車は欲しい。', translation: "But I want a car.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 236858, text: 'しかし私は恐れなかった。', translation: "But I wasn't afraid.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '小さな': [
    TatoebaSentence(id: 9183307, text: '小さな部屋ね。', translation: "It's a small room.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 147020, text: '小さな円を書きなさい。', translation: "Draw a small circle.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7465226, text: 'それは小さな問題だ。', translation: "It's a minor problem.", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  'シャワー': [
    TatoebaSentence(id: 215746, text: 'シャワーにするわ。', translation: "I'll take a shower.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 431686, text: 'シャワーが壊れた。', translation: "The shower is broken.", username: 'aliene', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8468049, text: 'シャワーを浴びる。', translation: "I'll take a shower.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '困る': [
    TatoebaSentence(id: 3551977, text: '杖がないと困る。', translation: "I need my cane.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 146118, text: '冗談だと思われては困る。', translation: "Don't think I'm joking.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1004646, text: '欲しい本いっぱいあって困るわ。', translation: "There are so many books that I want...what should I do?", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '暖かい': [
    TatoebaSentence(id: 9056162, text: '今日は暖かい日だな。', translation: "Today is a warm day.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9819175, text: '今日は暖かいな。', translation: "It's warm today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 220340, text: 'この冬は暖かい。', translation: "We are having a mild winter.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'テスト': [
    TatoebaSentence(id: 2246516, text: 'テスト文です。', translation: "This is a test sentence.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 202237, text: 'テストはどうだった？', translation: "How was your test?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11876557, text: 'テストをする。', translation: "I'm taking a test.", username: 'cia_UnitedStatesNa13', license: 'CC BY 2.0 FR'),
  ],
  'ペン': [
    TatoebaSentence(id: 11600418, text: 'これはペンです。', translation: "This is a pen.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9740651, text: 'ペンはある？', translation: "Do you have a pen?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1006916, text: 'ペン借りていい？', translation: "Can I borrow your pen?", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '零': [
    TatoebaSentence(id: 9714208, text: '零、一、二、三、四、五、六、七、八、九、十。', translation: "Zero, one, two, three, four, five, six, seven, eight, nine, ten.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 172624, text: '今は零下１０度だ。', translation: "It is ten degrees below zero now.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11102016, text: '水は零度で凍るんだよね？', translation: "Water freezes at zero Celsius, right?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '五日': [
    TatoebaSentence(id: 1614597, text: '今日は三月五日です。', translation: "Today is March 5th.", username: 'Meow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 235115, text: '五日待ってくれ。', translation: "Give me five days.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 554742, text: '五月五日は彼の誕生日だ。', translation: "His birthday is May 5th.", username: 'Namikaze', license: 'CC BY 2.0 FR'),
  ],
  '二十日': [
    TatoebaSentence(id: 8218418, text: '今日は金曜日、十月二十日だ。', translation: "Today is Friday, the twentieth of October.", username: 'Tanikaz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 139663, text: '卒業式は三月二十日に行われます。', translation: "The graduation ceremony will take place on March 20th.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8218495, text: '十月二十日の二時半に会えますか？', translation: "Can we meet on October 20th at 2:30?", username: 'Tanikaz', license: 'CC BY 2.0 FR'),
  ],
  'コピー': [
    TatoebaSentence(id: 8966994, text: 'コピーをもらえますか？', translation: "Can I get a copy?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 217684, text: 'これをコピーして下さい。', translation: "Please copy this.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2976842, text: 'コピーとっとかなきゃ。', translation: "I need to make a copy.", username: 'Fukuko', license: 'CC BY 2.0 FR'),
  ],
  '閉める': [
    TatoebaSentence(id: 13739047, text: 'ドアを閉めるね。', translation: "I'll close the door.", username: 'HAGNi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8663690, text: 'ドアを閉めるの、忘れないでよ。', translation: "Don't forget to close the door.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9675804, text: '今日は早めに閉めるよ。', translation: "Today we are closing earlier.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'いくら': [
    TatoebaSentence(id: 5332, text: 'いくらですか？', translation: "How much is it?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11878994, text: '給料はいくら？', translation: "What is your salary?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10934618, text: 'いくらだった？', translation: "How much did it cost?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '晴れる': [
    TatoebaSentence(id: 8560347, text: '明日は晴れると思う。', translation: "I think it will be sunny tomorrow.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9029517, text: '明日は晴れるよ。', translation: "It will be fine tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 143003, text: '晴れるのかなあ？', translation: "I wonder if it will be nice.", username: 'scornfulpen', license: 'CC BY 2.0 FR'),
  ],
  'グラム': [
    TatoebaSentence(id: 11529712, text: '生エビが500グラム欲しいです。', translation: "I want half a kilo of fresh shrimps.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901908, text: '卵は一個五十グラムぐらいです。', translation: "An egg is about fifty grams.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11112063, text: '500グラムでおいくら？', translation: "How much for half a kilo?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '入口': [
    TatoebaSentence(id: 2988140, text: 'ここは入口ではありません。', translation: "This is not the entrance.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11262118, text: '数人が入口でたむろしていた。', translation: "Some people were hanging around at the entrance.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3697584, text: '入口の側で立った。', translation: "He stood by the entrance.", username: 'ii_desu', license: 'CC BY 2.0 FR'),
  ],
  'セーター': [
    TatoebaSentence(id: 3715087, text: 'このセーターどう思う？', translation: "What do you think of this sweater?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 223604, text: 'このセーターは暖かい。', translation: "This sweater is warm.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11529722, text: 'そのセーターいいですね。', translation: "I like that sweater.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '厚い': [
    TatoebaSentence(id: 1278238, text: 'この本はとても厚い。', translation: "This book is very thick.", username: 'mandel59', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11839588, text: '分厚い本だな。', translation: "The book is thick.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 554738, text: 'その本は厚いが、高くはない。', translation: "That book is thick, but it's not very expensive.", username: 'Namikaze', license: 'CC BY 2.0 FR'),
  ],
  '背': [
    TatoebaSentence(id: 154632, text: '私は背が高い。', translation: "I am tall.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2324386, text: '彼女は背が高い。', translation: "She is tall.", username: 'eastasiastudent', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9478232, text: '君って背が高いの？', translation: "Are you tall?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'たばこ': [
    TatoebaSentence(id: 203425, text: 'たばこは吸いますか。', translation: "Do you smoke?", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 203415, text: 'たばこは体に悪いよ。', translation: "Smoking is bad for your health.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 84699, text: '父はたばこを吸う。', translation: "My father smokes.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '四日': [
    TatoebaSentence(id: 189545, text: '雨は四日間降り続いた。', translation: "The rain lasted four days.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1063558, text: '韓国旅行が三泊四日で三万円だって。激安だよね。', translation: "A trip to Korea for 3 nights and four days is 30,000 yen. That's super cheap.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1244715, text: '三日たち、四日たち、風が一度吹き、雨が二度降りました。', translation: "Three days passed, four days passed. The wind blew once, it rained twice.", username: 'Scott', license: 'CC BY 2.0 FR'),
  ],
  '答える': [
    TatoebaSentence(id: 11912972, text: 'その質問に答えるのは簡単だよ。', translation: "That question is easy to answer.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8733012, text: '君が質問に答える番だよ。', translation: "It's your turn to answer the question.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9344034, text: '彼が答える前に一瞬の間があった。', translation: "He hesitated before answering.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'ネクタイ': [
    TatoebaSentence(id: 12300728, text: 'ネクタイは？', translation: "Where is your tie?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 198631, text: 'ネクタイは必要ですか。', translation: "Do I need a tie?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10002384, text: 'そのネクタイ、いいね。', translation: "I like your tie.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '帰る': [
    TatoebaSentence(id: 161895, text: '7時に帰るよ。', translation: "I'll be back at seven o'clock.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8699812, text: '家に帰るの？', translation: "Are you going home?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 492778, text: '君はいつ帰る？', translation: "When are you going home?", username: 'hectorvk', license: 'CC BY 2.0 FR'),
  ],
  '今晩': [
    TatoebaSentence(id: 171215, text: '今晩暇かな？', translation: "Are you free tonight?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2076508, text: '今晩来ませんか？', translation: "Why don't you come over tonight?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 171224, text: '今晩は予定がある？', translation: "What are you doing tonight?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '上げる': [
    TatoebaSentence(id: 10101505, text: 'これが欲しいなら上げるよ。', translation: "I'll give you this if you want it.", username: 'moxy', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12056085, text: '大空を見上げる。', translation: "I look up at the sky.", username: 'xyz_13', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 217629, text: 'これを上げるの手伝って。', translation: "You wanna help me lift this up?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '疲れる': [
    TatoebaSentence(id: 2234707, text: '彼はすぐに疲れる。', translation: "He gets tired easily.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1678604, text: '今日は疲れる一日だった。', translation: "Today was a tiring day.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11027711, text: '重いスマホで手が疲れる。', translation: "My hand gets tired with the heavy phone.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  'すぐに': [
    TatoebaSentence(id: 214821, text: 'すぐに戻るよ。', translation: "I will be back soon.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 214893, text: 'すぐに行きます。', translation: "I'm coming at once.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 214824, text: 'すぐに戻ってね。', translation: "Come back soon.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '暑い': [
    TatoebaSentence(id: 171593, text: '今日は暑い。', translation: "It's hot today.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13252710, text: '暑い。', translation: "It's hot.", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8971861, text: '暑いですね。', translation: "It's hot, isn't it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '二十歳': [
    TatoebaSentence(id: 1771858, text: 'ローリーは二十歳だ。', translation: "Laurie is twenty years old.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1147846, text: '僕はまだ二十歳になっていない。', translation: "I'm not twenty years old yet.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1185764, text: '彼女は二十歳になったばかりである。', translation: "She has just turned twenty.", username: 'hambird', license: 'CC BY 2.0 FR'),
  ],
  // 六日 (むいか) is rare in the corpus with a literal match - the third
  // sentence has no linked English translation on Tatoeba.
  '六日': [
    TatoebaSentence(id: 10693896, text: 'トムは、六日間だけ迷子の犬を預かることにしました。', translation: "Tom only looked after the stray for 6 days.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10693894, text: '私が通っている学校では、八月六日は平和の大切さを心に刻む１日として毎年『平和学習』が行われます。', translation: "At the school I attend, August 6th is observed each year as \"Peace Learning Day\" to emphasize the importance of peace.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10979964, text: '六日に郵便局で荷物を送りました。', username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '涼しい': [
    TatoebaSentence(id: 171486, text: '今日は涼しいです。', translation: "It's cool today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901732, text: '秋は涼しいです。', translation: "Autumn is cool.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4260186, text: '今日はちょっと涼しいね。', translation: "Today is a little cold, huh?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'プール': [
    TatoebaSentence(id: 11252740, text: 'プールに行くんだ。', translation: "We're going to the pool.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8937779, text: 'トムはプールで泳いだ。', translation: "Tom swam in the pool.", username: 'lowteq', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11455486, text: 'プールがあるの？', translation: "Do you have a pool?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'つける': [
    TatoebaSentence(id: 124843, text: '電気をつけて下さい。', translation: "Please turn on the light.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 201970, text: 'テレビをつけて。', translation: "Please turn on the television.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2378466, text: 'トムはテレビをつけた。', translation: "Tom turned on the TV.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'ギター': [
    TatoebaSentence(id: 13428417, text: '君はギター弾く？', translation: "Do you play the guitar?", username: 'demiurgastel', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 226063, text: 'ギターが欲しいです。', translation: "I want a guitar.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 226054, text: 'ギターが弾けますか。', translation: "Can you play the guitar?", username: 'blay_paul', license: 'CC BY 2.0 FR'),
  ],
  'だんだん': [
    TatoebaSentence(id: 179431, text: '空はだんだん暗くなった。', translation: "The sky became darker and darker.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 203062, text: 'だんだん暖かくなります。', translation: "It will get warmer and warmer.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10680231, text: 'だんだん分かってきたよ。', translation: "I'm beginning to understand.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'ゆっくり': [
    TatoebaSentence(id: 192953, text: 'ゆっくり歩け。', translation: "Walk slowly.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5241324, text: 'ゆっくり食べて。', translation: "Eat slowly.", username: 'nihonjin', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10914911, text: 'ごゆっくりどうぞ。', translation: "Take your time.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '開く': [
    TatoebaSentence(id: 173557, text: '校門は8時に開く。', translation: "The gates of the school open at eight.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 179575, text: '銀行は９時に開く。', translation: "Banks open at nine o'clock.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2478353, text: 'ドアが開く音がした。', translation: "I heard the door open.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'カレー': [
    TatoebaSentence(id: 10049665, text: 'カレーは好きですか？', translation: "Do you like curry?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 223873, text: 'このカレーは辛すぎる。', translation: "This curry is too hot.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10912664, text: '今日もカレーよ。', translation: "Today it will also be Japanese curry.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ちょうど': [
    TatoebaSentence(id: 202921, text: 'ちょうど五時です。', translation: "It is just five o'clock.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 504217, text: '８時半ちょうどです。', translation: "It's exactly half-past eight.", username: 'blay_paul', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11199174, text: 'ちょうど終わりました。', translation: "I just finished it.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ボールペン': [
    TatoebaSentence(id: 8389362, text: 'これはボールペン。', translation: "This is a pen.", username: 'rizkisaid', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8755627, text: 'ボールペンでご記入ください。', translation: "Please write with a ballpoint pen.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10965344, text: 'このボールペンはいくらですか？', translation: "How much is this ballpoint pen?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ナイフ': [
    TatoebaSentence(id: 199353, text: 'ナイフがない。', translation: "There is a knife missing.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1006944, text: 'ナイフが必要だ。', translation: "I need a knife.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6828177, text: 'ナイフで切ります。', translation: "I'll cut it with a knife.", username: 'D0UG', license: 'CC BY 2.0 FR'),
  ],
  'そっち': [
    TatoebaSentence(id: 1490049, text: '今そっちに行く。', translation: "I'm going there now.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3050857, text: 'そっちは今何時？', translation: "What time is it there?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9147404, text: '元気だよ。そっちはどう？', translation: "I'm fine. How about you?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '汚い': [
    TatoebaSentence(id: 2706891, text: 'トムの部屋は汚い。', translation: "Tom's room is dirty.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10967393, text: '汚いかな？', translation: "Is it dirty?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12662562, text: 'キーボードは、汚い。', translation: "The keyboard is filthy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '吸う': [
    TatoebaSentence(id: 159554, text: '私はタバコを吸うよ。', translation: "I smoke cigarettes.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7577219, text: 'トムはタバコを吸う。', translation: "Tom smokes.", username: 'Kisu', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9785032, text: '紙は油を吸うよ。', translation: "Paper absorbs oil.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'フォーク': [
    TatoebaSentence(id: 4867728, text: 'フォークを下さい。', translation: "I'd like a fork.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6828189, text: 'フォークでパスタを食べます。', translation: "I eat pasta with a fork.", username: 'D0UG', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 197199, text: 'フォークをいただけますか。', translation: "Could we have a fork?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '消える': [
    TatoebaSentence(id: 141975, text: '雪はすぐに消えるだろう。', translation: "The snow will soon disappear.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 205237, text: 'それは決して消えることはない。', translation: "That will never disappear.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5304, text: '彼は嫌な思い出が消えることを願っている。', translation: "He wishes to erase bad memories.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '食堂': [
    TatoebaSentence(id: 145793, text: '食堂はどこですか。', translation: "Where is the cafeteria?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9387713, text: '食堂ってもう開店した？', translation: "Is the cafeteria open yet?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2858060, text: 'さっき食堂でトムに会ったよ。', translation: "I just ran into Tom in the cafeteria.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  'どうして': [
    TatoebaSentence(id: 778978, text: 'どうして？', translation: "Why?", username: 'marloncori', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 778975, text: 'どうしてですか？', translation: "Why?", username: 'marloncori', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 201455, text: 'どうして私なの？', translation: "Why me?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '貸す': [
    TatoebaSentence(id: 1484647, text: '金を貸す。', translation: "I lend money.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 179699, text: '金を借りるのも貸すのも嫌だ。', translation: "I don't want to lend or borrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1484845, text: 'トムに金を貸すのは嫌だ。', translation: "I don't like it when Tom borrows money from me.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
  ],
  'ズボン': [
    TatoebaSentence(id: 11667953, text: '僕のズボンはどこ？', translation: "Where are my trousers?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 879005, text: 'このズボンいくら？', translation: "How much are these pants?", username: 'arihato', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12829786, text: 'ズボンを履きなさい。', translation: "Put your pants on.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'キロ': [
    TatoebaSentence(id: 3559171, text: '体重何キロ？', translation: "What do you weigh?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8655622, text: '何キロ減ったの？', translation: "How many kilograms did you lose?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12437149, text: '体重が3キロ落ちた。', translation: "I lost three kilograms.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'スリッパ': [
    TatoebaSentence(id: 214119, text: 'スリッパをはいてください。', translation: "Please put on your slippers.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10185311, text: '僕のスリッパがない。', translation: "I can't find my slippers.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 223615, text: 'このスリッパに履きかえてください。', translation: "Please put on these slippers.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'メートル': [
    TatoebaSentence(id: 9392652, text: '身長は、１メートル７０です。', translation: "My height is one meter seventy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12014388, text: '1,000メートルは1キロです。', translation: "A thousand meters is one kilometer.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 141977, text: '雪は２メートル積もった。', translation: "Snow fell two meters deep.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  // 一月 as "one month" (ひとつき) almost never shows up in the corpus -
  // every hit uses the kanji for "January" (いちがつ) instead.
  '一月': [
    TatoebaSentence(id: 1035889, text: '一月に彼に会いました。', translation: "I met him in January.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 216722, text: 'サムは一月にスキーに行った。', translation: "Sam went skiing in January.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10192046, text: 'その紅の花は一月に咲きます。', translation: "The crimson flowers will bloom in January.", username: 'terrywallwork', license: 'CC BY 2.0 FR'),
  ],
  '働く': [
    TatoebaSentence(id: 199994, text: 'トムはよく働く。', translation: "Tom is a good worker.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 91309, text: '彼女はよく働く。', translation: "She works hard.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1771808, text: '私は日曜日に働く。', translation: "I work on Sunday.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  'それでは': [
    TatoebaSentence(id: 205769, text: 'それでは、失礼いたします。', translation: "Uh, will you excuse me?", username: 'Fukuko', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 205757, text: 'それでは後ほどうかがいます。', translation: "I'll see you later.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1602097, text: 'それでは、天気予報の時間です。', translation: "Now it's time for the weather forecast.", username: 'jathonjet', license: 'CC BY 2.0 FR'),
  ],
  'マッチ': [
    TatoebaSentence(id: 195348, text: 'マッチを持っていますか。', translation: "Have you got a match?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 110768, text: '彼はマッチをすった。', translation: "He struck a match.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2996267, text: 'マッチで遊んではいけません。', translation: "You shouldn't play with matches.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '寒い': [
    TatoebaSentence(id: 5183, text: '寒い。', translation: "It's cold.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 945288, text: '寒いです。', translation: "It's cold.", username: 'Quazel', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8699915, text: '外は寒い？', translation: "Is it cold outside?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'タクシー': [
    TatoebaSentence(id: 11574812, text: 'タクシー来たわよ。', translation: "The cab is here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 203734, text: 'タクシーが到着した。', translation: "The taxi has arrived.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11535697, text: 'タクシーを呼んで。', translation: "Call a taxi.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'アパート': [
    TatoebaSentence(id: 229463, text: 'いいアパートね。', translation: "This is a great apartment.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9808965, text: 'アパートを借りたいです。', translation: "I want to rent an apartment.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 151853, text: '私達はアパートを借りた。', translation: "We rented an apartment.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'そちら': [
    TatoebaSentence(id: 10285699, text: 'そちらはどうですか？', translation: "How about your place?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2182818, text: 'そちらは今何時ですか？', translation: "What time is it there?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 213476, text: 'そちらの天気はいかがですか。', translation: "How's the weather there?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'レコード': [
    TatoebaSentence(id: 231234, text: 'あのレコードはこの店で買ったんだ。', translation: "I bought that record in this store.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 156708, text: '昨晩はレコードを聴きました。', translation: "I listened to some records last night.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 106131, text: '彼は私にレコードをくれました。', translation: "He gave me a record.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'それから': [
    TatoebaSentence(id: 12171775, text: 'それからトムは何て言ったの？', translation: "What did Tom say next?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2469096, text: 'それから10年が経った。', translation: "10 years have passed since then.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 205907, text: 'それから彼女はまた歩き始めた。', translation: "Then she began to walk again.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
  ],
  '日曜日': [
    TatoebaSentence(id: 971235, text: '今日は日曜日です。', translation: "Today is Sunday.", username: 'Heinz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1054565, text: '日曜日は暇です。', translation: "I'm free on Sunday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 122156, text: '日曜日に会おう。', translation: "Let's meet on Sunday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'お酒': [
    TatoebaSentence(id: 7490665, text: 'トムはお酒を飲む。', translation: "Tom drinks.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9826790, text: 'お酒は飲めないの。', translation: "I can't drink alcohol.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10175938, text: 'ワインはお酒です。', translation: "Wine is an alcoholic beverage.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '半分': [
    TatoebaSentence(id: 121255, text: '半分よこせ。', translation: "Give me half of it.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 169127, text: '仕事の半分はかたづいた。', translation: "The job is half done.", username: 'wakatyann630', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 192462, text: 'りんごの半分が腐っている。', translation: "Half of the apples are rotten.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'お風呂': [
    TatoebaSentence(id: 11763476, text: 'お風呂の時間です。', translation: "It's time to take a bath.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 226694, text: 'お風呂沸いてる？', translation: "Is the bath ready?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8752695, text: 'お風呂に入りなさい。', translation: "Take a bath.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '暗い': [
    TatoebaSentence(id: 194357, text: 'もう暗いよ。', translation: "It is already dark.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 184872, text: '外は暗い。', translation: "It is dark outside.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1608716, text: 'ここは暗い。', translation: "It's dark in here.", username: 'Bah_Dure', license: 'CC BY 2.0 FR'),
  ],
  '危ない': [
    TatoebaSentence(id: 183597, text: '危ない！', translation: "Look out!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2432348, text: '彼の命が危ない。', translation: "His life is in danger.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11597082, text: 'ここは危ないよ。', translation: "It's not safe here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'もう一度': [
    TatoebaSentence(id: 4765273, text: 'もう一度？', translation: "Again?", username: 'Doremi391', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3496871, text: 'もう一度読んで。', translation: "Read it again.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2581791, text: 'もう一度やって。', translation: "Do it again!", username: 'OrangeTart', license: 'CC BY 2.0 FR'),
  ],
  '死ぬ': [
    TatoebaSentence(id: 144251, text: '人間は必ず死ぬ。', translation: "Man is bound to die.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 168166, text: '死ぬのが怖い。', translation: "I am afraid of dying.", username: 'huizi99', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3983713, text: '死ぬな！', translation: "Don't die.", username: 'Rikkel', license: 'CC BY 2.0 FR'),
  ],
  'お姉さん': [
    TatoebaSentence(id: 7957662, text: 'あれは私のお姉さんです。', translation: "That is my sister.", username: 'Kaguya', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 91886, text: '彼女はトムのお姉さんです。', translation: "She's Tom's sister.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2196428, text: 'お姉さんはお元気ですか。', translation: "How's your sister?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '生まれる': [
    TatoebaSentence(id: 84547, text: '父は私が生まれる前に死にました。', translation: "My father died before I was born.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 194696, text: 'メアリーは来月赤ん坊が生まれる。', translation: "Mary is going to have a baby next month.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1167386, text: 'メアリーは来月赤ちゃんが生まれる。', translation: "Mary is going to have a baby next month.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '弁当': [
    TatoebaSentence(id: 188944, text: '駅で弁当を買った。', translation: "I bought a box lunch at the station.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1483518, text: '私は毎日昼に弁当を食べます。', translation: "I eat lunch every day at noon.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 174062, text: '公園でお弁当を食べませんか。', translation: "How about having our lunch in the park?", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  'コップ': [
    TatoebaSentence(id: 224105, text: 'コップは水でいっぱいだ。', translation: "The glass is full of water.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3552051, text: 'コップが一つ欲しい。', translation: "I want a glass.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901831, text: 'そのコップはあなたのです。', translation: "That glass is yours.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '渡る': [
    TatoebaSentence(id: 11365390, text: '道を渡る時は気をつけて。', translation: "Be careful when you cross the street.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 119594, text: '彼が道路を渡るのを見た。', translation: "I saw him cross the street.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 370892, text: '渡る世間に鬼はない。', translation: "All humans are good at heart.", username: 'reiji', license: 'CC BY 2.0 FR'),
  ],
  'バター': [
    TatoebaSentence(id: 8649281, text: 'バターはどこ？', translation: "Where's the butter?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 198004, text: 'バターを取ってください。', translation: "Please pass me the butter.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 198015, text: 'バターはミルクから出来る。', translation: "Butter is made from milk.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  'どうも': [
    TatoebaSentence(id: 9672957, text: 'どうもありがとう。', translation: "Many thanks.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8533930, text: 'どうも！', translation: "Thanks!", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1680680, text: 'どうも、元気か？', translation: "Hi, how are you?", username: 'aka_aj', license: 'CC BY 2.0 FR'),
  ],
  'ハンカチ': [
    TatoebaSentence(id: 9086586, text: 'ハンカチを落とされましたよ。', translation: "You dropped your handkerchief.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 111230, text: '彼はハンカチを取り出した。', translation: "He took out his handkerchief.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 223306, text: 'このハンカチはいくらですか。', translation: "How much is this handkerchief?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'スプーン': [
    TatoebaSentence(id: 214526, text: 'スプーンがありません。', translation: "There is a spoon missing.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4449036, text: 'すいません、スプーンを頂けますか？', translation: "Excuse me, may I have a spoon?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9009296, text: 'トムはまだスプーンが使えない。', translation: "Tom can't use a spoon yet.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '一昨日': [
    TatoebaSentence(id: 9314693, text: '「いつ戻ったの？」「一昨日だよ」', translation: "\"When did you return?\" \"I came back the day before yesterday.\"", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 190602, text: '一昨日成田に着きました。', translation: "I arrived at Narita the day before yesterday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10470698, text: '一昨日は月曜日だったよ。', translation: "The day before yesterday was Monday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'こっち': [
    TatoebaSentence(id: 1296635, text: 'こっちに来て。', translation: "Come here.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2152589, text: 'こっちへおいで。', translation: "Come here.", username: 'nihonjin', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4819327, text: 'こっち見ないで。', translation: "Don't look at me.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '飴': [
    TatoebaSentence(id: 5272, text: '飴がほしい。', translation: "I want a piece of candy.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8569734, text: '飴ちょうだい。', translation: "I want some candy.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12957147, text: '飴は歯に悪い。', translation: "Candy is bad for your teeth.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  // おまわりさん had no usable kana hits - these use the お巡りさん kanji
  // spelling of the same word.
  'おまわりさん': [
    TatoebaSentence(id: 837427, text: 'お巡りさんに聞け！', translation: "Ask a policeman!", username: 'Scott', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10557689, text: 'そこのお巡りさんに聞いてみて。', translation: "Ask the policeman over there.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 123608, text: '道に迷ったらお巡りさんに尋ねなさい。', translation: "If you lose your way, ask a policeman.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '住む': [
    TatoebaSentence(id: 104367, text: '彼は住む家がなかった。', translation: "He had no house to live in.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8605168, text: '住む場所を探しているんだ。', translation: "I'm looking for a place to live.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12703175, text: 'パリに住むつもりよ。', translation: "I'm going to live in Paris.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '歩く': [
    TatoebaSentence(id: 100083, text: '彼は歩くのが速い。', translation: "He's a quick walker.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2328282, text: '私は歩くのが遅い。', translation: "I walk slowly.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 81753, text: '歩くの疲れたよ。', translation: "I am tired from walking.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  'ストーブ': [
    TatoebaSentence(id: 12976249, text: 'ストーブをつけた。', translation: "I turned on the stove.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11104374, text: 'サミは新しいストーブを買った。', translation: "Sami bought a new stove.", username: 'MrJuice', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8742530, text: '本当にストーブを消した？', translation: "Are you sure you turned off the stove?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'お腹': [
    TatoebaSentence(id: 404097, text: 'お腹がすいた。', translation: "I'm hungry!", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3589612, text: 'お腹痛い。', translation: "My stomach hurts.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8601946, text: 'お腹いっぱい？', translation: "Are you full?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'エレベーター': [
    TatoebaSentence(id: 227886, text: 'エレベーターはどこですか。', translation: "Where is the elevator?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11065745, text: 'エレベーターが来たよ。', translation: "The lift arrived.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1142909, text: 'エレベーターはありますか？', translation: "Is there an elevator?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  // そうして (and; like that) is genuinely scarce in the corpus - only
  // these 2 sentences contain the literal word.
  'そうして': [
    TatoebaSentence(id: 11924238, text: '今もそうしてます。', translation: "I'm still doing that.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 143325, text: '是非ともそうしてください。', translation: "Please do so by all means.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '土曜日': [
    TatoebaSentence(id: 171533, text: '今日は土曜日です。', translation: "It's Saturday today.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12133220, text: '土曜日が好きです。', translation: "I like Saturdays.", username: 'HAGNi', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11255344, text: '明日は土曜日だ。', translation: "Tomorrow is Saturday.", username: 'sh5555', license: 'CC BY 2.0 FR'),
  ],

  // JLPT N5 Vocabulary continued (words 601-662, the rest of the set) -
  // again only the words not already covered above. ラジオカセット has zero
  // matches anywhere in the Tatoeba corpus, so it's skipped entirely here -
  // the live "Load sentence from Tatoeba" button will just come back empty
  // for it too, which is expected rather than a bug.
  '夕飯': [
    TatoebaSentence(id: 9032609, text: '夕飯いつ？', translation: "When's dinner?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10531072, text: '夕飯にしましょう。', translation: "Let's have dinner.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11242897, text: '夕飯はもう食べたの？', translation: "Have you eaten dinner yet?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '黄色い': [
    TatoebaSentence(id: 1614327, text: '花は黄色い。', translation: "Flowers are yellow.", username: 'Meow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 212174, text: 'その黄色いのをいただきましょう。', translation: "I'll take the yellow one.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1614341, text: '私の前に黄色い車がある。', translation: "There's a yellow car in front of me.", username: 'Meow', license: 'CC BY 2.0 FR'),
  ],
  'さあ': [
    TatoebaSentence(id: 3488678, text: 'さあ泳ごう。', translation: "Let's swim.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3506680, text: 'さあ行こう。', translation: "Now let's go.", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 74849, text: 'さあね。', translation: "You can search me!", username: 'fcbond', license: 'CC BY 2.0 FR'),
  ],
  'デパート': [
    TatoebaSentence(id: 2852998, text: 'トムはデパートへ買い物に行った。', translation: "Tom went shopping at a department store.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 190113, text: '一番近いデパートはどこにありますか。', translation: "Where's the nearest department store?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 212947, text: 'そのデパートの前に書店がある。', translation: "There is a bookstore in front of the department store.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '習う': [
    TatoebaSentence(id: 148159, text: '習うより慣れろ。', translation: "Practice makes perfect.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9694324, text: 'フランス語を習うのは簡単だよ。', translation: "Learning French is easy.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1470952, text: 'エスペラント語を習うのは楽しい。', translation: "Esperanto is a fun language to learn.", username: 'may', license: 'CC BY 2.0 FR'),
  ],
  '履く': [
    TatoebaSentence(id: 3452320, text: '木靴を履くのが好きだ。', translation: "I like to wear clogs.", username: 'tomo', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10047195, text: '雨とか雪の時は、必ずブーツを履くんだ。', translation: "I always wear boots when it rains or snows.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9803276, text: 'メアリーはズボンを履くことが好きなんだ。', translation: "Mary likes wearing pants.", username: 'Sim5634', license: 'CC BY 2.0 FR'),
  ],
  'どなた': [
    TatoebaSentence(id: 3488192, text: 'どなた？', translation: "Who is it?", username: 'arnab', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13236536, text: 'どなたですか。', translation: "Who are you?", username: 'atitarev', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9696168, text: 'どなたでもできますよ。', translation: "Anyone can do that.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '引く': [
    TatoebaSentence(id: 236073, text: '１０引く６はいくつですか。', translation: "What is 6 subtracted from 10?", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 162305, text: '私はよく風邪を引く。', translation: "I often catch cold.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12161027, text: '風邪引くよ。', translation: "You'll catch a cold.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '奥さん': [
    TatoebaSentence(id: 118033, text: '彼の奥さんはどんな人？', translation: "What is his wife like?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 229377, text: 'いい奥さんになるよ。', translation: "You will make a good wife.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 188552, text: '奥さんはお元気？', translation: "How is the wife?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '開ける': [
    TatoebaSentence(id: 140344, text: '窓を開けるな。', translation: "Don't open the window.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10140809, text: 'この箱は開けるな。', translation: "Don't open this box.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12462036, text: 'これ、どうやて開けるんですか？', translation: "How do you open this?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '差す': [
    TatoebaSentence(id: 10117520, text: '人を指差すのは失礼だよ。', translation: "It's not polite to point at others.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11623817, text: '指を差すのは失礼だと、母から教わりました。', translation: "My mother taught me that it's not polite to point.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 12403325, text: '瞳孔は陽が差すところでは収縮します。', translation: "The pupils of the eyes contract in sunlight.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  // ワイシャツ only had these 2 genuine matches.
  'ワイシャツ': [
    TatoebaSentence(id: 11833918, text: '俺の白のワイシャツ、どこ？', translation: "Where's my white dress shirt?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 192073, text: 'ワイシャツにボタンをつけて。', translation: "Would you sew a button on my shirt?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '居る': [
    TatoebaSentence(id: 79273, text: '幽霊は本当に居るのだろうか。', translation: "Do ghosts really exist?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 199976, text: 'トムは家の中に居る。', translation: "Tom is in the house.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 234465, text: 'あしたは家に居るつもりだ。', translation: "I will stay home tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '月曜日': [
    TatoebaSentence(id: 437970, text: '今日は月曜日。', translation: "It is Monday today.", username: 'aliene', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 175603, text: '月曜日です。', translation: "It's Monday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8703102, text: '月曜日でいい？', translation: "Is Monday OK?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '菓子': [
    TatoebaSentence(id: 2318419, text: '和菓子が食べたい。', translation: "I want to eat Japanese sweets.", username: 'orcrist', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11038989, text: 'このお菓子は甘いです。', translation: "This candy is sweet.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8936226, text: 'お菓子買ってよ。', translation: "Buy me a snack.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '金曜日': [
    TatoebaSentence(id: 12954881, text: '今日は金曜日だよ。', translation: "Today is Friday.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 738372, text: 'やっと金曜日ですよ。', translation: "It's finally Friday.", username: 'DeSha', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9776974, text: '金曜日はどうですか？', translation: "How about Friday?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'おばあさん': [
    TatoebaSentence(id: 118383, text: '彼のおばあさんは元気そうです。', translation: "His grandmother looks healthy.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1780332, text: '先週、おばあさんは８１歳になった。', translation: "Last week my grandmother turned 81 years old.", username: 'Bah_Dure', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 227593, text: 'おばあさんが隣に越してきた。', translation: "An old lady moved into the place next door.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  '飛ぶ': [
    TatoebaSentence(id: 125778, text: '鳥は飛ぶ。', translation: "Birds fly.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 82635, text: '蜂は花から花に飛ぶ。', translation: "Bees fly from flower to flower.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 125774, text: '鳥は翼で飛ぶ。', translation: "Birds fly with their wings.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
  ],
  'まっすぐ': [
    TatoebaSentence(id: 195365, text: 'まっすぐ行け。', translation: "Go straight on.", username: 'Take32', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 195363, text: 'まっすぐ前を見てください。', translation: "Look straight ahead.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 220294, text: 'この道をまっすぐ行きなさい。', translation: "Go straight along this street.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'まずい': [
    TatoebaSentence(id: 9252333, text: 'このスープ、まずいっ。', translation: "This soup tastes awful.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10792679, text: 'このビザはまずい。', translation: "This pizza is terrible.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10596542, text: 'まずいぞ、トム。', translation: "That's no good, Tom.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'ご飯': [
    TatoebaSentence(id: 12056104, text: 'ご飯はうまい。', translation: "The rice is delicious.", username: 'xyz_13', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10049463, text: 'ご飯はあるの？', translation: "Do you have rice?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11001460, text: 'ご飯にする？', translation: "Do you want rice?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '水曜日': [
    TatoebaSentence(id: 1458037, text: '今日は水曜日です。', translation: "Today is Wednesday.", username: 'marcelostockle', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1600532, text: '水曜日は空いていますか。', translation: "Are you free on Wednesday?", username: 'jathonjet', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1600587, text: '水曜日は仕事があります。', translation: "I have work on Wednesday.", username: 'jathonjet', license: 'CC BY 2.0 FR'),
  ],
  '狭い': [
    TatoebaSentence(id: 143357, text: '世間は狭いですね。', translation: "It's a small world.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901739, text: '日本は狭い国です。', translation: "Japan is a small country.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9183332, text: '狭い部屋だね。', translation: "It's a small room.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '易しい': [
    TatoebaSentence(id: 433124, text: 'その本は易しい。', translation: "The book is easy.", username: 'qahwa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2436430, text: 'エスペラントの発音は易しい。', translation: "Esperanto is easy to pronounce.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 193198, text: 'もっと易しい事を聞いて下さい。', translation: "Ask me something easier.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  '六つ': [
    TatoebaSentence(id: 349891, text: '一つ、二つ、三つ、四つ、五つ、六つ、七つ、八つ、九つ、十。', translation: "One, two, three, four, five, six, seven, eight, nine, ten.", username: 'human600', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13541629, text: '私の望遠鏡で木星とその六つの衛星を見ることができます。', translation: "My telescope can see Jupiter and its six moons.", username: 'LeviHighway', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9718152, text: '桃子は、おはじきを「一つ、二つ、三つ、四つ、五つ、六つ、七つ、八つ、九つ、十」まで数えると黙り込んでしまいました。お母さんが「十一、十二、十三」と続けると嬉しそうに「十四、十五、十六」と数え続けました。', translation: "Momoko counted the marbles: \"One, two, three, four, five, six, seven, eight, nine, ten\" and then went silent. When her mother continued with \"eleven, twelve, thirteen,\" she happily picked up with \"fourteen, fifteen, sixteen.\"", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '着く': [
    TatoebaSentence(id: 5111, text: 'いつ着くの？', translation: "When do we arrive?", username: 'zhouj1955', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11075511, text: 'もう、着くよ。', translation: "I'm arriving now.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 99581, text: '彼は明日着く予定だ。', translation: "He is due to arrive tomorrow.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'テープレコーダー': [
    TatoebaSentence(id: 223521, text: 'このテープレコーダーは４万円しました。', translation: "I paid 40,000 yen for this tape recorder.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 202372, text: 'テープレコーダーはテーブルの上に置いてあった。', translation: "The tape recorder was lying on the table.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 191857, text: 'このテープレコーダーに４万円払ったんだよ。', translation: "I paid 40,000 yen for this tape recorder.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '脱ぐ': [
    TatoebaSentence(id: 122097, text: '入り口で靴を脱ぐことになっている。', translation: "We are supposed to take off our shoes at the entrance.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11660617, text: 'メアリーがコートを脱ぐの手伝ってあげなさい。', translation: "Help Mary take off her coat.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10128949, text: '家に入る時は、靴を脱ぐよ。', translation: "I take off my shoes when I go in my house.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '八つ': [
    TatoebaSentence(id: 1151917, text: '彼女は八つだ。', translation: "She is eight.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10798102, text: '八つの時にエクアドルに行ったよ。', translation: "I went to Ecuador when I was eight years old.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 519714, text: 'そこに八つの小石があった。', translation: "There were eight pebbles there.", username: 'blay_paul', license: 'CC BY 2.0 FR'),
  ],
  '閉まる': [
    TatoebaSentence(id: 124992, text: '店は７時に閉まる。', translation: "The store closes at seven.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 207644, text: 'その店は１１時に閉まる。', translation: "The store closes at eleven.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7486229, text: '2時半に閉まる。', translation: "We close at 2:30.", username: 'Ninja', license: 'CC BY 2.0 FR'),
  ],
  '木曜日': [
    TatoebaSentence(id: 2670479, text: '今日は木曜日です。', translation: "Today is Thursday.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 169944, text: '昨日は木曜日だった。', translation: "Yesterday was Thursday.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10125615, text: '今年のバレンタインデーは、木曜日に当たります。', translation: "This year, Valentine's Day falls on a Thursday.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'はがき': [
    TatoebaSentence(id: 2204224, text: 'はがきを送ってよ。', translation: "Send me a postcard.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7486196, text: 'はがきを集める。', translation: "I collect postcards.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 78067, text: '両親が私にはがきを送ってくれた。', translation: "My parents sent me a postcard.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  // ラジカセ only had this 1 genuine match in the whole corpus.
  'ラジカセ': [
    TatoebaSentence(id: 1174918, text: '確かに今の日本では、「ラジカセ」はもう古い言葉なのかもしれない。', translation: "The word \"raji-kase\", meaning radio cassette in Japan, is probably more of an antiquated term by now.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '花瓶': [
    TatoebaSentence(id: 202394, text: 'テーブルの上に花瓶がある。', translation: "There is a vase on the table.", username: 'Kaede', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4181508, text: '花瓶割ったの誰？', translation: "Who broke the vase?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 186559, text: '花瓶は両手で持ちなさい。', translation: "Hold the vase in both hands.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  // キログラム only had this 1 genuine match in the whole corpus.
  'キログラム': [
    TatoebaSentence(id: 163114, text: '私の体重は５８キログラムです。', translation: "My weight is 58 kilograms.", username: 'mookeee', license: 'CC BY 2.0 FR'),
  ],
  'お兄さん': [
    TatoebaSentence(id: 11140874, text: 'お兄さんは何歳ですか？', translation: "How old is your brother?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8805648, text: '彼女はお兄さんを愛している。', translation: "She loves her older brother.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9665644, text: 'トムのお兄さんを知っている？', translation: "Do you know Tom's older brother?", username: 'moxy', license: 'CC BY 2.0 FR'),
  ],
  '登る': [
    TatoebaSentence(id: 188723, text: '猿は木に登る。', translation: "Monkeys climb trees.", username: 'wat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8619699, text: '壁に登るな。', translation: "Don't climb on the wall.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10287480, text: '富士山に登るつもりなんだ。', translation: "I'm going to climb Mt. Fuji.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'キロメートル': [
    TatoebaSentence(id: 11003498, text: '駅から図書館まで二キロメートルあります。', translation: "It's two kilometers from the station to the library.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2157706, text: 'この川は200キロメートルの長さがあります。', translation: "This river is two hundred kilometers long.", username: 'Blanka_Meduzo', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 137819, text: '台風１１号は、毎時２０キロメートルの速さで北上中です。', translation: "Typhoon No.11 is moving up north at twenty kilometers per hour.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  '忘れる': [
    TatoebaSentence(id: 218786, text: 'これだけは忘れるな。', translation: "Just don't forget this.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7490672, text: 'トムを忘れるな。', translation: "Don't forget Tom.", username: 'Ninja', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1518862, text: 'それを忘れる。', translation: "Forget it.", username: 'ABChessel', license: 'CC BY 2.0 FR'),
  ],
  '無くす': [
    TatoebaSentence(id: 9938147, text: '財布を無くしたことある？', translation: "Have you ever lost your wallet?", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 6967722, text: 'メアリーは鍵を無くした。', translation: "Mary lost the key.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 3406015, text: 'トムはチケットを無くした。', translation: "Tom lost his ticket.", username: 'TY', license: 'CC BY 2.0 FR'),
  ],
  '咲く': [
    TatoebaSentence(id: 8637349, text: '花はもうすぐ咲くよ。', translation: "The flowers will soon blossom.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 121521, text: '梅の花は3月に咲く。', translation: "Plum blossoms come out in March.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 234475, text: 'あじさいは６月に咲く。', translation: "The hydrangea blooms in June.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '並べる': [
    TatoebaSentence(id: 1105450, text: 'あれ？並べる順番があべこべだけど、いいの？', translation: "Huh? The order is reversed, is that alright?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11056040, text: '暖房器具の時期に、冷房器具を並べるようなデパートは、たちまちつぶれる。', translation: "Department stores that display air conditioners in heater season will very quickly go out of business.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 5065428, text: '集合を表記するには、{1,2,3}のように元を書き並べる。', translation: "A set should be expressed as a list of elements like {1, 2, 3}.", username: 'MisterTrouser', license: 'CC BY 2.0 FR'),
  ],
  '吹く': [
    TatoebaSentence(id: 670057, text: '風が吹く。', translation: "The wind blows.", username: 'szaby78', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 111041, text: '彼はフルートを吹くことが出来る。', translation: "He is able to play the flute.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13611144, text: '吹く!', translation: "Blow!", username: 'stao', license: 'CC BY 2.0 FR'),
  ],
  '弾く': [
    TatoebaSentence(id: 354488, text: '私はバイオリンを弾く。', translation: "I play the violin.", username: 'slovakia25', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 197710, text: 'ピアノを弾くのは難しい。', translation: "It is difficult to play the piano.", username: 'KK_kaku_', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13428417, text: '君はギター弾く？', translation: "Do you play the guitar?", username: 'demiurgastel', license: 'CC BY 2.0 FR'),
  ],
  // 勤める only had these 2 genuine matches.
  '勤める': [
    TatoebaSentence(id: 155525, text: '私は石油会社に勤めている。', translation: "I work for an oil company.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9552333, text: 'トムは隔週休２日制の会社に勤めてるんだ。', translation: "Every other week, Tom's company gives him a second day off work.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '鳴く': [
    TatoebaSentence(id: 11605430, text: '犬は「ワンワン」と鳴く。', translation: "The dog goes \"woof-woof\".", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 11101908, text: '猫は「ニャー」と鳴く。', translation: "The cat says \"meow\".", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1284062, text: '鳥は鳴く。', translation: "Birds sing.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
  ],
  'お皿': [
    TatoebaSentence(id: 8822145, text: 'お皿がいるよ。', translation: "I need a plate.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2730929, text: 'お皿が汚れています。', translation: "The plate is dirty.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2270822, text: 'お皿を洗います。', translation: "I'll wash the dishes.", username: 'e4zh1nmcz', license: 'CC BY 2.0 FR'),
  ],
  '晩ごはん': [
    TatoebaSentence(id: 3155689, text: 'ママ、晩ごはん何時？', translation: "Mom, when's supper?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1069179, text: '晩ごはんはもう食べましたか。', translation: "Have you eaten supper yet?", username: 'tigro1973', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 4704222, text: '今日の晩ごはん何？', translation: "What's for dinner tonight?", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
  '磨く': [
    TatoebaSentence(id: 4772267, text: '歯を磨くことを忘れないで。', translation: "Remember to brush your teeth.", username: 'Ishao', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 492913, text: '男の人は歯を磨く。', translation: "The man brushes his teeth.", username: 'hectorvk', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 222245, text: 'この靴を磨く必要がある。', translation: "These shoes need polishing.", username: 'arnab', license: 'CC BY 2.0 FR'),
  ],
  '昼ごはん': [
    TatoebaSentence(id: 226830, text: 'お昼ごはんよ。', translation: "Lunch is on.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 553919, text: 'お昼ごはんは食べたの？', translation: "Have you eaten lunch yet?", username: 'Namikaze', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8853877, text: '昼ごはんどこで食べるの？', translation: "Where are you going to eat lunch?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '朝ごはん': [
    TatoebaSentence(id: 9226970, text: '朝ごはん、できたよ。', translation: "Breakfast is ready.", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8587389, text: '朝ごはんは何食べた？', translation: "What did you have for breakfast?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9533457, text: '朝ごはんの時間ですよ。', translation: "It's time for breakfast.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '手洗い': [
    TatoebaSentence(id: 227063, text: 'お手洗いはどこですか。', translation: "Where is the bathroom?", username: 'nihonjin', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10901763, text: 'お手洗いはこちらです。', translation: "The bathroom is this way.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10983325, text: 'お手洗いは二階にあります。', translation: "The bathroom is on the second floor.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  'おばさん': [
    TatoebaSentence(id: 1484897, text: 'こちらは私のおばさんたちです。', translation: "These ladies are my aunts.", username: 'marshmallowcat', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 1056567, text: 'おばさんがCDアルバムを一枚くれた。', translation: "My aunt gave me an album.", username: 'mookeee', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 9851210, text: 'トムはおばさん好きなのよ。', translation: "Tom likes mature women.", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  // 温い only had this 1 genuine match in the whole corpus.
  '温い': [
    TatoebaSentence(id: 11320513, text: 'ここはちょっと温いですね？', translation: "It's a bit warm in here, isn't it?", username: 'small_snow', license: 'CC BY 2.0 FR'),
  ],
  '曇る': [
    TatoebaSentence(id: 171528, text: '今日は曇っている。', translation: "It's cloudy today.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 8688640, text: '曇ってる？', translation: "Is it cloudy?", username: 'bunbuku', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 7562208, text: 'マスクをつけると眼鏡が曇る。', translation: "When I wear a mask, my glasses get steamed up.", username: 'Sonata', license: 'CC BY 2.0 FR'),
  ],
  // 賑やか is rare in the corpus - only 3 sentences total contain it, and
  // 2 of those have no linked English translation.
  '賑やか': [
    TatoebaSentence(id: 8868907, text: '台湾のナイトマーケットは、賑やかなものだ。', translation: "Taiwan's night market is bustling.", username: 'mochico', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13056392, text: '今日の商店街はかなり賑やかな感じだね。', username: 'Gardenia', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 13056422, text: 'あそこってかなり賑やかな街で、歩いているだけで活気を感じるよね。', username: 'Gardenia', license: 'CC BY 2.0 FR'),
  ],
  // 字引き (using the 字引 spelling) only had these 2 genuine matches.
  '字引き': [
    TatoebaSentence(id: 13713984, text: 'この漢字を字引で引いてみて。', translation: "Look up this kanji in the dictionary.", username: 'GreySquirrel', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 103261, text: '彼は生き字引と呼ばれている。', translation: "He is called a walking dictionary.", username: 'tommy__san', license: 'CC BY 2.0 FR'),
  ],
  'うるさい': [
    TatoebaSentence(id: 551962, text: 'うるさい！', translation: "Hey you, shut up!", username: 'furagwa', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 10559200, text: 'ここ、うるさいわね。', translation: "It's noisy in here.", username: 'small_snow', license: 'CC BY 2.0 FR'),
    TatoebaSentence(id: 2521029, text: 'トムは食にうるさい。', translation: "Tom is particular about what he eats.", username: 'tommy_san', license: 'CC BY 2.0 FR'),
  ],
};
