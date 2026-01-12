'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "8f2e986b2b0cfb743659680c201b82b7",
"version.json": "63ea98702d9bab0b6ff1f81887a9dd61",
"index.html": "ac28c5ab871dc83e3caabd3a5304bbb5",
"/": "ac28c5ab871dc83e3caabd3a5304bbb5",
"main.dart.js": "5fe009d4deb2afa2aa9555e23aa3353d",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "9ac14790c8d065203e78e6155f2be6ae",
".git/config": "1e23a8baf2b7ae70361727af23e2ec5e",
".git/objects/0d/6d36328d5d6aaee9cf481eec9bdf44aa4b2e40": "d3bcc429664240e32edb4820c6c537ed",
".git/objects/92/54b7fdc6c8ae52c2882be959d47ec64bcbcef1": "a570151ebd47a49b6521313e576917f3",
".git/objects/3e/d493f2ecfeb09b0a1afacad8ed74cf4143a4a5": "5e06b390b90ffae1fafaf5b6159d3e94",
".git/objects/3e/786097e4f2e60c33b08adc3d0a70eadeb241fa": "2abe291b18f577f588c156493d261dd9",
".git/objects/50/3eae5f5d6d4e1722c38c95f7833b0b1e186e9a": "ce2fd8487cb0414c562c8786a172d7ee",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/69/c8044cc7667be9f9164013272f2b426c7ecd83": "dcca3f0d3fe81073005a7d45aab45700",
".git/objects/69/b2023ef3b84225f16fdd15ba36b2b5fc3cee43": "6ccef18e05a49674444167a08de6e407",
".git/objects/3c/5009d7a6351beb2e572d8be47d805d9fca00c7": "d5baea755c18f158c5c22a5b2ed06c7e",
".git/objects/51/fcdf6856ca0dd20f4b5b90448d4ade70fd51d7": "69153546ac7df4032d3da7410206499e",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/0b/67021b884544b9aea93b0c50cea6df1e510322": "8f8ee79cc476dbbfd1d2166252126424",
".git/objects/93/b006b75e54ea97139fb6038adb4c606cd98fa4": "848041c70963af1b37f0f076adfa5ee9",
".git/objects/93/a11a06c73db2f9260b55290e0acb007fd2e317": "f5c10c11c41faf57933c7e08b4b28454",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/94/41094b47986427d671ab49acfd75277fdd63d9": "bd8e090626891f833df3cadcc79e9c8f",
".git/objects/0e/bd1df8bae64d4dcc19181c18d4836df6da4240": "46ca9f87f66b0441aede1a1cd3bed8ce",
".git/objects/60/d76309fd38fdd6133cdd7b0f580ae79b909c35": "614175b74ebc93086e7dde40aad82895",
".git/objects/33/3ec82c64a3e95d36a1915c47f7116562d30e2c": "6e568591391bd1da3e33122545734efe",
".git/objects/02/3f51370b8524713666893d2fe709dce638dfcb": "217a60abfcae82d2b729c560f9752ca9",
".git/objects/a3/39549ab425b9ae9390b9ef3fc5c43fd4f12eec": "173c105a979c760efa43d2119a6e04e0",
".git/objects/b2/9b23f4ebaf65fd4f65e65b65e2711f905992d3": "99367388218ca3bf8b8f8348a5a29c14",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/ad/2f90b78480aeb6608226d9db4ecbd3ec06aaeb": "4add97a99941aa0e9eed0f2173416ade",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/d0/1fa899ec75bc168544eaef09af6d6790371407": "a89c49b21fa190b6f4aefd2867905a90",
".git/objects/b4/ce6d4d2511890b5af57657ad27f37dd5aa0d95": "6551221f7fe4bd2d661cdb486e25b213",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/bc/7d993f94baf32ca11e5f5dc5412aac12a668a9": "d782f8a82d795ae96da7df117f4c51bd",
".git/objects/ae/6d3ed4027ac4797ab9a57436a0d149d2e9df1f": "462a25f3d49468c300622e298d88bf37",
".git/objects/ab/946c1503a0dd9581bbf8b70c5aa67d5f1e78b1": "b69169381d6d2ce00682532637c6204b",
".git/objects/ab/c84d06204db4c7591d3e48db3c08d63695bf0c": "c99229945589ddd1ddc7c16b5ed47cc1",
".git/objects/e5/dea9a8cc14782f28bad3731f88519efcca6c8e": "3cf91cbb88311f1e0a620b553d54ae4a",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/c0/31969996a8344451a6722ea803aab572f01ca9": "b8fd9d6c1ed459bf1d1e5aa619a69bee",
".git/objects/fc/3cdfb8ab3ed3dd3de8a31e044fb7d1b37f8815": "af5cd1144d66c6e664e8adfde1a8deae",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/ca/28c42816e1ba98b5202e9a751a7a71c42d96e6": "963cafb9d7043e8a4b08248318128b18",
".git/objects/ca/6e39faa8febde7477fdb9204d1fa705100edb4": "d5b0201a35326c29b71e31ee7588153f",
".git/objects/ca/bc9760f220c55b876e7f52d88a7cf2ee6c47e1": "63a3a6f1f3222da6a729433b2f5161d5",
".git/objects/e4/0351b498b0a719e28672a1bf7239eed587ff2d": "80810d71812199f00e22285a6c98d7b6",
".git/objects/c8/2b92b8096e3268b5814eb17a6c0fea446fcb1f": "c840086ed6b3925fc2ed254859101d41",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/c1/f8e25520da347714c0fa932b28a2f52f7027b2": "fd838123de4b705642cb042cc98bf8a7",
".git/objects/ec/c97ca903f9c04ca27fd5e255b309cf5bdbda41": "7817f813682f1d4a2322183383978513",
".git/objects/27/38e4a5ad605d918be34a6c7525b93a157cec02": "eedf512fc68c22982c24a9fe25e2f9d0",
".git/objects/7c/068034e8938b49c2277e9b4a13f4a5e907c3a2": "65e3c03a33fe1ffa21f21ecca237d240",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/1f/daa6a72ed6ef93c7504f0ee1dc6395168ac79b": "0f8b0989a1677d7d5a37c597d4f9cb0d",
".git/objects/73/1c1b27ba1e3cfd0acf566ac2e02a2cab414102": "12fe791fbf5f1c15a8200a1dd830769b",
".git/objects/1a/f411b36873d29dd0e387e98f582b8e96819535": "ed050d20aee0f0d1a501a94ab0680c67",
".git/objects/28/11f4d1c168ed6e6591b470236f025068ea3450": "09bf7fd4899073829f55d63ec9c2be91",
".git/objects/28/05c3790c49306742ae4e359583c70b3f743207": "8d2235bf35a83aefea327f617d13b7c0",
".git/objects/8f/4952bacb298ad9ff126a349e8b052003640acf": "e62ecc415bf18cb13f1004cd0a574777",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/4d/e949cccdb5b0687c7ee1ab3f8ceed26e7dc0b1": "6d318235d5550f44a0f070aff1243627",
".git/objects/4d/607f501b5d71a189da75a56597c1418e8b83cf": "3a85c86d3d53c27a2434e1abb275ff06",
".git/objects/81/b1667e57f4512b4acc866f946c850a0a2116dc": "5dccc332dbea5801fcdf1bff561dec8e",
".git/objects/2a/29678584c2adf847f39752ae79a848ecbed48b": "eb947dab2661c40f195dc5d720d7079c",
".git/objects/43/638bf66f51d893ba6340afb3758238b1785756": "b287fb82117b6a276d824de24e884517",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/07/283e971e4fcbc4a74fbb0c073dffa7329d4fd8": "effd306b1c8dcfaa7b3c0911cbded73e",
".git/objects/36/ea3cf4d8795574c6036a3cdd551604c7663b95": "63b52e28d6f326b38ee1dcacaa19ea9c",
".git/objects/5c/af07633d3cc344d7795ff1798d0dcb36ab7dd3": "36e08c93b22b13a0f98360140c39dd5d",
".git/objects/91/711ca3c6755034165b38d9a3bea3c334d5f449": "27419bfd0ed1bccc776ab65d24b8c949",
".git/objects/91/8a39562e36afecc98ba0be7af91f06e34f9712": "9c58963518c8572b8b7d8ec66df63836",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/54/8bdb5eee4bed60b1b0dc0df529fe646826cef6": "a031f042a726b4b1d2d4327f8d0926cd",
".git/objects/98/47d85aee006c11d71233d3dee8f34ced55e0ee": "4ecc1041d59239801c49167c2a530587",
".git/objects/37/8859f613fc32f04cd8b9cf4a7b530796828558": "26ea275db66d3006c03629501816deee",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/01/5911029dd4bc44ab7608d7ce4932180293dc4e": "adc4435746de47fd8157afa0bb722c70",
".git/objects/01/069f9def2a1197da9b4634036b53291d30864f": "bbdd474d9100dfb9cdee69b3f1da348a",
".git/objects/39/4f735a99974263d4995df43c84e6adf089ed7f": "6076a67a907c57cbf16085db043333b4",
".git/objects/52/b8618fb0444d77a71837f407fb75c433359115": "5889c88ad27bc0fbae096c3f12c1da5e",
".git/objects/90/d9547676b1264b50f2f88f6afd4fc193df365f": "7a6407ee0b8bd7ff2e1b1064c2d89311",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/ba/8e0f64818681a43ef528519b26a2385f7f0000": "c1bdef1fef757f641bd835df13b7aff6",
".git/objects/a0/6633a69791d9eca82b7a43ae1484b93af613f1": "34f0f517e2fa622e1b298c6c8005d173",
".git/objects/b8/144682a20d0cc4cbd1aa35809ac0df0ee3d206": "b94adb786a403e1a680db3b855f2782b",
".git/objects/a9/be93a8a94f36fea710f912b9610ad7445a6aac": "0faf38d992aee15afb7556271293320d",
".git/objects/a9/91f51138ffe059d588003dc7936aff059a0428": "b73a35563fa129bd884d8b5c53ee9231",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/db/b3cc60226b8c1009f34dd6d0533e1e23f98651": "15af9524d664e39a6f548412b724c2e3",
".git/objects/a8/a168a74c25445876e1f019d4209786d10f7134": "fa1d3e0f3d92f657e972714b0211eadf",
".git/objects/de/8d630a7af561dd8b89ae5a6bbc2e5e5d59f34e": "391c7f1ca4861f5bbd7e829e2c2ab286",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/c3/8a45ac39ea27549c0c3354c6f88022ade0828d": "64fbf0198ecf051b2b0e3b18ecf25a09",
".git/objects/c4/5a1568a5a8c8c085d05b8abc1c1581668590cc": "6401f1732967de2fb5e0c0e7712e6c9e",
".git/objects/ea/d1b0934265fc6072b2146dea078090cc4d7e44": "dc25ece605f18f8a1797ff236bb14835",
".git/objects/e1/3a8b4834c6093ad8cd6d9e4d2e4cdb97c03806": "de13261ccab74dff232ee4a1be88183c",
".git/objects/cc/fab74c1f56c330985060e2247607eaedb3c7d7": "ad5b6117df489509af208438785f208b",
".git/objects/cc/7026ad6c9a4ce7d05921b62de7b4ad7cfedc96": "4c82778c93ffcb3c29646b5a8041cd9d",
".git/objects/e6/eb8f689cbc9febb5a913856382d297dae0d383": "466fce65fb82283da16cdd7c93059ff3",
".git/objects/e8/ca15dc8a2eacbe08ae81837ecf305b15be9190": "58f4586bde41d57d4bd643bb23aaeae7",
".git/objects/ff/566fcd39cbc03f497598181e05efd5d8f5066c": "9d4dd343e7941ed110368fceda8d0f6d",
".git/objects/f6/cc06a0d471df5df1f35082b09b45fced798d05": "b3ed116bd3c82d600d635270058f4345",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/f1/53a3782febb35dcafcf75b4d1fb114864ce982": "fd06cf37f62369c3fcaf86db724fc4a3",
".git/objects/f1/39c8d871511cc6d1011b2fdad50812a7affe58": "270d872a8e15f373bb7415c56d629eb2",
".git/objects/f1/17b0db7231f0a2d29c7cc9a64af636075229de": "1b038096f4dba1ab4bd5a85df2ba0011",
".git/objects/ce/92cd3b2e220ef3518d82beea08d317a0e84c8d": "b9e2761c7a8279f8c37a2d7968979994",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/1b/00810262bd2a85a0b3ec3fbe6c37349509d0cf": "40efa41318b7657cd76a0cafd6325a01",
".git/objects/84/3f51fae8a85cd48440800d46552e3ae8202089": "d5a0bbd9c8492ed340d9238ad4d80c8f",
".git/objects/23/6dadfcee476acd973e5b2f0e6bf84b32dfa889": "d7ba3e207df7a72956a6c4206cb561b6",
".git/objects/23/01c87b2d1a57c785ffb4fceda3309b5bddc14a": "3b65dfa8642feb692320d75a78685aef",
".git/objects/15/7f4877689b08169d032759d2609e333b4fd20b": "0aed1e52a65e5820c5fff8f503e1f2cc",
".git/objects/12/08eeae806d129f724185cceceacf27721bd3f4": "dc11b8086b5c420a50691f5c4f045e6e",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/40/4ca5240b2bd857d4150370e9adcd9517abf8a1": "d422d9b65ee0a2b1e4fa62e2a5f519b9",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "0fa3096814bd1448614b113db10e4618",
".git/logs/refs/heads/gh-pages": "db161d41e9e1d14f3ebb5013b71812e4",
".git/logs/refs/remotes/origin/gh-pages": "5678ce726cf4d25b3909d51cd0418d19",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/gh-pages": "81288de171443218699a302ad0380853",
".git/refs/remotes/origin/gh-pages": "81288de171443218699a302ad0380853",
".git/index": "0847d780eaf9eaa503b07806aab33766",
".git/COMMIT_EDITMSG": "8439beb8b1732c0a2985d22d90c57484",
"assets/NOTICES": "db8bf4602e012b7f25d72509967123aa",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "7e14f6757d1fb30d61d65ffcb94a74b5",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "d7d83bd9ee909f8a9b348f56ca7b68c6",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "b5da8db90a00acf3ee39c11abb66b5e1",
"assets/fonts/MaterialIcons-Regular.otf": "0ea93278b10e40b66c0543b25c9eaad3",
"assets/assets/images/defaultProfile.jpg": "24b7a54feb8cf942bd7fbbbd702ac5d4",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
