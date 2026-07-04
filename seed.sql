-- ============================================================
-- seed.sql  |  從 Google Sheet 匯入資料
-- ============================================================

-- 建立 UUID extension (若尚未建立)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. Trips
-- ============================================================
INSERT INTO "Trips" ("TripId", "ReadOnlyId", "Name", "StartDate", "EndDate", "CoverUrl", "CreatedAt")
VALUES
(
  'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',
  '9b4e1d72-3a0f-4c8e-a293-5f7b6e2d0a84',
  '🌸 2026 京阪名古屋大拇指櫻花季',
  '2026-04-04',
  '2026-04-12',
  'https://images.unsplash.com/photo-1522273400909-fd1a8f77637e',
  NOW()
),
(
  'a4fd9d5b-4c38-4101-ba22-cd80369da12b',
  'ea73282c-5c93-4c64-8313-8ced98c9201b',
  '濟州哈些優',
  '2027-01-08',
  '2027-01-13',
  NULL,
  NOW()
);

-- ============================================================
-- 2. TripInfos
-- ============================================================
INSERT INTO "TripInfos" (
  "TripId",
  "OutboundFlightNo", "OutboundAirline", "OutboundDepartureTime", "OutboundArrivalTime",
  "OutboundDepAirport", "OutboundArrAirport", "OutboundFlightRemark", "OutboundImageUrl",
  "InboundFlightNo", "InboundAirline", "InboundDepartureTime", "InboundArrivalTime",
  "InboundDepAirport", "InboundArrAirport", "InboundFlightRemark", "InboundImageUrl",
  "TripRemark"
)
VALUES
(
  'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',
  'MM722', '樂桃', '2026-06-25 2:15', '2026-06-25 5:00',
  'TPE(桃園)', 'NGO(名古屋)', E'Test\nTest',
  'https://drive.google.com/thumbnail?id=1cQrEt2TUy_p0RWBxLkQe6ltGLiWU4ZfN&sz=w1000',
  'IT222', '虎航', '2026-07-08 18:30', '2026-07-08 21:45',
  'KIX', 'TPE', NULL,
  'https://drive.google.com/thumbnail?id=1wjeooB6GDYcaz2SXQd_UE5TlxoDj1YJa&sz=w1000',
  NULL
);

-- ============================================================
-- 3. PackingItems
-- ============================================================
INSERT INTO "PackingItems" ("ItemId", "Name", "IsEssential", "Checked", "SortOrder", "CreatedAt")
VALUES
  ('e888879c-6e4b-44b7-84fc-635c3fe0fff3', '護照',     TRUE,  FALSE, 1, '2026-07-01 20:42:57+00'),
  ('ea5c053b-9b06-4185-8fb4-53093fdde5f4', '錢包',     TRUE,  FALSE, 2, '2026-07-01 20:43:17+00'),
  ('351b3052-4d8a-45a0-894b-aaaa2c8eebaa', '墨鏡',     FALSE, TRUE,  3, '2026-07-01 20:43:28+00'),
  ('9b8ca65e-04b8-4707-a0a1-4b68ae0c778a', '御朱印帳', FALSE, FALSE, 4, '2026-07-01 20:44:01+00');

-- ============================================================
-- 4. Schedules
-- ============================================================
INSERT INTO "Schedules" ("TripId","Day","Date","Id","GroupId","AltOrder","SortOrder","StartTime","EndTime","AttractionName","Remark","GoogleMapLink")
VALUES
-- Day 1
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','d34bc84a-c0fc-413b-9fe8-f0c8f306d1e4','d34bc84a-c0fc-413b-9fe8-f0c8f306d1e4',0,0,'23:30',NULL,'家→台北 (移動)','桃機第一航廈',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','52033599-fd10-477c-8fbd-1af249a5fee7','52033599-fd10-477c-8fbd-1af249a5fee7',0,1,'02:10','06:00','航班 MM722 (移動)','23:30到機場, 1:55飛機-5:45到名古屋',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','bde0acd9-cfee-4a8b-a8ff-c6b519a16574','bde0acd9-cfee-4a8b-a8ff-c6b519a16574',0,2,'07:00',NULL,'出關、買名鐵車票 (景點)','7:00出關 名鐵線(μ－ＳＫＹ) 中部國際機場>(3站)>名鐵名古屋>步行550m到飯店(35min) Montblanc Hotel Raffine Nagoya Ekimae モンブランホテルラフィネ名古屋駅前 https://maps.app.goo.gl/884amAjLevuB6kQ57 放行李',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','1a69f4bb-615b-4091-96f1-14e2fcac34df','1a69f4bb-615b-4091-96f1-14e2fcac34df',0,3,NULL,NULL,'飯店寄行李 (作業)','Montblanc Hotel Raffine Nagoya Ekimae','https://maps.app.goo.gl/XQ1yWjgKgRHJfAxr7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','71aefdd1-7b36-4851-9b32-97aee0711b6c','71aefdd1-7b36-4851-9b32-97aee0711b6c',0,4,'10:30',NULL,'早餐~天然酵母の食パン専門店 つばめパン＆Milk 名駅店','去趣寫(禮拜六沒開)但官網跟google寫有營業 上午 8:00-11:00 要抽號碼牌 https://tsubamepan.jp/waiting/ (等待人數跟時間可以查) 離飯店850 公尺','https://maps.app.goo.gl/B1dvkCkZczTVLYtU8'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','0c874952-0711-4f59-8707-31b9e412eb8e','0c874952-0711-4f59-8707-31b9e412eb8e',0,5,'11:30',NULL,'熱田神宮 (景點)','9:30 (要記得在名古屋車站買一日票) 自動販賣機販售地下鉄全線24時間券￥760、週末環保票成人620日元(不能乘坐Yurorito Line高架區間（大曽根～小幡緑地）以及名鐵巴士、青波線。) 步行400m> 名鐵名古屋>名鐵常滑線(急行)1站>金山（愛知） 金山>名城線(3站)>熱田神宮傳馬町一號出口 9:50到 要吃鰻魚飯就坐到傳馬町(靠近南門和熱田蓬萊軒)，先抽鰻魚飯號碼牌 從南門走到本殿就要走將近10分鐘','https://maps.app.goo.gl/L51wJvmCGvC2MTB99'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','b70562fe-635b-4a77-8d29-eea2a16cb1ad','b70562fe-635b-4a77-8d29-eea2a16cb1ad',0,6,'11:30',NULL,'午餐熱田蓬萊軒 本店 (吃喝)','可先抽號碼牌','https://maps.app.goo.gl/kFbAG2baPHBppFk59'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','5cab5e8c-1db7-4e0a-afba-1d5d3f56fd2e','5cab5e8c-1db7-4e0a-afba-1d5d3f56fd2e',0,7,'14:30',NULL,'鶴舞公園看櫻花 (景點)','熱田神宮傳馬町>名城線(5站)>上前津車站 上前津車站>鶴舞線(1站)>鶴舞車站 180m到公園 36min','https://maps.app.goo.gl/3PQfkL92HFAzZLKc7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','8823b9f8-2945-428d-a6e2-942e30d5f106','8823b9f8-2945-428d-a6e2-942e30d5f106',0,9,'16:30',NULL,'回名鐵名古屋(吃甜點or回去休息)','回名鐵名古屋 鶴舞車站>(JR)中央本線(2站)>名古屋車站(17MIN) HARBS 名鐵名古屋店 https://maps.app.goo.gl/7tUL2HT7RW1NzFds7 (飯店)Montblanc Hotel Raffine Nagoya Ekimae https://maps.app.goo.gl/884amAjLevuB6kQ57','https://maps.app.goo.gl/LDQiQvFTnddaxk5z5'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','377f3fc9-e704-46d0-86d6-308c7ab880d5','377f3fc9-e704-46d0-86d6-308c7ab880d5',0,10,'18:30',NULL,'榮商圈、唐吉軻德逛街','名古屋車站>東山線(2站)>榮（愛知）','https://maps.app.goo.gl/bNUWsPXg4ixVWQrG6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04','bdead5ee-2d42-4507-9445-9bcee579720b','bdead5ee-2d42-4507-9445-9bcee579720b',0,11,'19:00',NULL,'晚餐~ほるたん屋 栄店(訂位19:00)',NULL,'https://maps.app.goo.gl/xzT9iAQSQBdZ41TGA'),
-- Day 1 (no id rows → gen_random_uuid())
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',1,'2026-04-04',gen_random_uuid(),gen_random_uuid(),0,8,'22:00',NULL,'Montblanc Hotel Raffine Nagoya Ekimae',NULL,'https://maps.app.goo.gl/XQ1yWjgKgRHJfAxr7'),

-- Day 2
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','6b3fbb4b-f356-4319-848d-63ece7825248','6b3fbb4b-f356-4319-848d-63ece7825248',0,0,'07:00',NULL,'起床、早餐 (作業)','9:30出門、退房寄放行李',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','0b7f3f7a-a40a-4f05-8188-25a40272c759','0b7f3f7a-a40a-4f05-8188-25a40272c759',0,2,NULL,NULL,'坐車到京都(45分) (移動)','名古屋車站>新幹線(1站)>京都車站 到飯店放行李 京都車站>山陰本線(1站)>梅小路京都西>步行350 公尺(7min) 京都Emion飯店 https://maps.app.goo.gl/NYbVWLKFBZFJRPTcA 11:00放行李','https://maps.app.goo.gl/LDQiQvFTnddaxk5z5'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','a922765b-6ce8-4b92-bd9f-74effe219cbf','a922765b-6ce8-4b92-bd9f-74effe219cbf',0,1,'11:00',NULL,'京都Emion飯店 (住宿)','放行李','https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','87935343-9ccc-4783-b741-922654738b90','87935343-9ccc-4783-b741-922654738b90',0,3,'11:30',NULL,'河原町吃午餐','吃什麼再找','https://maps.app.goo.gl/kXDhbMaPwWvX7UtS8'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','3ce63fe4-4654-48ee-ad53-62747dbd3f3e','3ce63fe4-4654-48ee-ad53-62747dbd3f3e',0,4,'13:00',NULL,'下鴨神社 (景點)','三條（京都）>京阪本線(2站)>出町柳 下鴨神社春有櫻花御守 https://maps.app.goo.gl/AzMsovybAEP8RiqR7','https://maps.app.goo.gl/XEWdCvWdhrF6wdcj8'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05',gen_random_uuid(),gen_random_uuid(),0,8,'13:00',NULL,'河合神社','河合神社 https://maps.app.goo.gl/JkjYnHYZNhUozLeEA 求「美麗」的神社','https://maps.app.goo.gl/Pwh6v3HH9Vwx6ZgU6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','2b395673-46cf-4174-af13-7079e2fe4438','2b395673-46cf-4174-af13-7079e2fe4438',0,5,'15:00','20:00','逛街(河原町、四條) (景點)','出町柳>京阪本線(2站)>三條（京都） 15:00~19:00 Kawaramachi OPA https://maps.app.goo.gl/gbfFP8FFzzGc95Ww9 各種百貨公司','https://maps.app.goo.gl/38W1vSeA6JdgmooYA'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','4e6e7d20-0a6f-48ff-be02-890db0b24e3c','4e6e7d20-0a6f-48ff-be02-890db0b24e3c',0,8,'20:00','21:30','和牛すき焼き京都ぱんが','預約20:00','https://maps.app.goo.gl/GvyXFj3yjo4ATAHTA'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','77a1e8d5-6b2f-46fd-bf22-d52027a05704','77a1e8d5-6b2f-46fd-bf22-d52027a05704',0,6,NULL,NULL,'京都Emion飯店 (住宿)','四條>烏丸線(2站)>京都車站>山陰本線(1站)>梅小路京都西','https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7'),
-- Day 2 備案
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','68d4af29-0eaf-4467-9365-78edc97b679d','a922765b-6ce8-4b92-bd9f-74effe219cbf',1,1,'11:00',NULL,'test被按2',NULL,NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',2,'2026-04-05','655f417a-925c-46ab-9764-637091db7e26','655f417a-925c-46ab-9764-637091db7e26',0,9,NULL,NULL,'test被按',NULL,NULL),

-- Day 3
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','62488270-1305-4efc-afbb-faeb795b5586','62488270-1305-4efc-afbb-faeb795b5586',0,0,'06:30',NULL,'起床 (作業)','6:30起床 7:45出門',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','a6b0fb0e-4382-42c4-aea7-5b3091fed477','a6b0fb0e-4382-42c4-aea7-5b3091fed477',0,1,'08:30',NULL,'mocomoco和服店換裝 (作業)','京都車站>市營巴206 City Bus(8站)>五条坂 步行78m(24分) 預約8:30 https://maps.app.goo.gl/v42cSPKDQNRVBrG79 可放行李 五點半前還衣服(可跨店還) (清水寺店、嵐山店、八坂神社店、伏見稻荷店)','https://maps.app.goo.gl/pRcqpQ69z1swfEHS6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','5807a417-9820-4a20-bc58-30abde2b4510','5807a417-9820-4a20-bc58-30abde2b4510',0,2,'10:00',NULL,'清水寺 (景點)','10:00到 早上6:00至下午6:00 500yen入園費','https://maps.app.goo.gl/jxBvCuTYqRJv7nF5A'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','5d628d4e-613e-4618-a27d-e86e207ad8a3','5d628d4e-613e-4618-a27d-e86e207ad8a3',0,3,'11:45',NULL,'安井金比羅宮 (景點)','從清水寺走900m 無論是健康、情感、習慣、人際關係或業障上的「緣」，信眾皆可前來祈求「斷惡緣、結善緣」 https://maps.app.goo.gl/uBbS9hzchVBZTxxP7 八坂庚申堂 經過可去(柯南聖地巡禮)','https://maps.app.goo.gl/3Z5TBfjHnkvVNvsM7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','c2ba3976-3a11-47e7-b777-3dbc8c8ae5fe','c2ba3976-3a11-47e7-b777-3dbc8c8ae5fe',0,4,'11:30',NULL,'午餐~らーめん錦 (吃喝)','抹茶拉麵','https://maps.app.goo.gl/6XnUEDNEjhQnDK5A9'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','163511f0-d526-4dbf-a1a5-f8f582a6b63a','163511f0-d526-4dbf-a1a5-f8f582a6b63a',0,5,NULL,NULL,'八坂神社 (景點)','再走600m 門票免費 花見小路通','https://maps.app.goo.gl/3Z5TBfjHnkvVNvsM7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','f07dc8ea-960e-498c-9a0f-15b8aeeaf04a','f07dc8ea-960e-498c-9a0f-15b8aeeaf04a',0,6,NULL,NULL,'下午茶-甘味どころ ぎをん 小森 (吃喝)','宇治金時, (還和服)','https://maps.app.goo.gl/chF89oaqW5z1SxEW7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06','31004772-64a4-46e9-b959-ccc832a14272','31004772-64a4-46e9-b959-ccc832a14272',0,7,NULL,NULL,'還和服 (作業)','八坂神社 祇園>202、206、207 City Bus>清水道(2站)','https://maps.app.goo.gl/pRcqpQ69z1swfEHS6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06',gen_random_uuid(),gen_random_uuid(),0,8,NULL,NULL,'伏見稻荷大社(看累不累決定','千本鳥居 狐狸御守很可愛 到山頂大概是40-50樓','https://maps.app.goo.gl/byFkAzi3k9duFgsJ8'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06',gen_random_uuid(),gen_random_uuid(),0,8,NULL,NULL,'新京極商店街小逛','昨天沒有逛完的河原町可以繼續逛過去到新京極商店街','https://maps.app.goo.gl/65kFo9qPFpes7Azw6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06',gen_random_uuid(),gen_random_uuid(),0,8,NULL,NULL,'晚餐~京都 炭火串焼 つじや 梅小路北店','居酒屋 京都 炭火串焼 つじや 梅小路北店','https://maps.app.goo.gl/kMJpmsKdEvfKEtwL9'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',3,'2026-04-06',gen_random_uuid(),gen_random_uuid(),0,8,NULL,NULL,'京都Emion飯店 (住宿)',NULL,'https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7'),

-- Day 4
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','d70d7f6f-58f4-4696-ab6c-89cce3f463c2','d70d7f6f-58f4-4696-ab6c-89cce3f463c2',0,0,'07:00','8:20','起床 (作業)','7:00起床 8:20出門',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','897b79fd-a63a-42a3-9e4a-f083ed391cbd','897b79fd-a63a-42a3-9e4a-f083ed391cbd',0,1,'8:20','09:30','坐車到平等院 (移動)','(8:36)梅小路京都西>山陰本線(1站)>京都車站 京都車站>奈良線(8站)>宇治車站>步行650m(50分)','https://maps.app.goo.gl/BcrmtFdvWabqG4dY7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','25f7a137-76e5-4ffb-8b6c-72053e1969a5','25f7a137-76e5-4ffb-8b6c-72053e1969a5',0,2,'09:30','11:00','平等院','平等院與十圓硬幣合照一下 庭院600日元，鳳凰堂加300日元 鳳凰堂購票在橋旁邊的建物，每20分鐘開放50名參觀 庭園8:30～17:30 鳳凰堂內部參觀＊9:30～16:10 (大概逛1~1.5小時)','https://maps.app.goo.gl/SqfuGRM8Gqt5kL1i7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','cc67691d-ba25-49c8-b2b7-72c88e07533f','cc67691d-ba25-49c8-b2b7-72c88e07533f',0,3,'11:00',NULL,'午餐-拉麵豬一 (吃喝)','吃的到第一批的話就吃(11:00) 吃拉麵豬一  (11:00吃)','https://maps.app.goo.gl/23mk9VorPosiRyCz7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','0e8acaa9-673b-4ade-8d63-7dc827cb5d96','0e8acaa9-673b-4ade-8d63-7dc827cb5d96',0,4,'12:00',NULL,'坐車到任天堂博物館 (移動)','稻荷車站>奈良線(7站)>ＪＲ小倉 600 公尺(28分)',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','e6bc8529-5d2c-43f4-a765-428960f6f2cf','e6bc8529-5d2c-43f4-a765-428960f6f2cf',0,5,'12:00','12:30','任天堂博物館 (景點)','宇治>奈良線(1站)>ＪＲ小倉 步行600m(從拉麵店16min) 要帶護照，現場人員"每個人"都檢查。 10個小金幣可以玩遊戲 在這3hr','https://maps.app.goo.gl/fWRSAKgXd1dCjjUs5'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','5a665c7d-ddb9-4fdc-8036-5b58e274e8cc','5a665c7d-ddb9-4fdc-8036-5b58e274e8cc',0,6,NULL,NULL,'下午茶-中村藤吉本店 (吃喝)','逛宇治附近的抹茶店','https://maps.app.goo.gl/am58gmwf8GDyzaH89'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','53c7466d-8fd4-4cae-a79a-5c0a42a7de4c','53c7466d-8fd4-4cae-a79a-5c0a42a7de4c',0,7,NULL,NULL,'(備案)哲學之道 (景點)','時間如果還早 祇園>203 City Bus>銀閣寺道>500m(33分)','https://maps.app.goo.gl/PtndWZi1wePTNTRR7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',4,'2026-04-07','6a1931f5-d1c4-4534-b440-5aeecf7f8195','6a1931f5-d1c4-4534-b440-5aeecf7f8195',0,8,NULL,NULL,'高級飯店-京都Emion飯店 (住宿)',NULL,'https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7'),

-- Day 5
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',5,'2026-04-08','90d945f9-6695-4848-a6cc-1fd90e217e66','90d945f9-6695-4848-a6cc-1fd90e217e66',0,0,'07:00','08:00','起床 (作業)','8:00出門',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',5,'2026-04-08','026320fc-7a16-4fc4-8709-22219aab0f00','026320fc-7a16-4fc4-8709-22219aab0f00',0,1,'08:00','09:20','去京都車站坐車 (移動)','梅小路京都西>山陰本線(1站)>京都車站 9:20到京都車站','https://maps.app.goo.gl/emg1D2ssznVb2L676'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',5,'2026-04-08','ebb51613-1f13-4512-9178-1243df183f85','ebb51613-1f13-4512-9178-1243df183f85',0,2,'09:40','19:00','天橋立、伊根舟屋oneday tour (作業)','集合時間：9:40 出發時間：9:50(導遊會舉GOGODAY的旗子) 地點：京都站八條口-站前觀光巴士停車場(看到ANANTI招牌後左轉)',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',5,'2026-04-08',gen_random_uuid(),gen_random_uuid(),0,8,'09:40','19:00','天橋立、智恩寺','天橋立特有打卡姿勢，從大腿縫隙欣賞 纜車票有包 單軌電車沒有包 午餐自理',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',5,'2026-04-08',gen_random_uuid(),gen_random_uuid(),0,8,'09:40','19:00','伊根舟屋','船票有包，海鷗餌100日圓',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',5,'2026-04-08','5fe5bf9d-f47d-4295-b474-7fbaaceae158','5fe5bf9d-f47d-4295-b474-7fbaaceae158',0,5,'19:00','20:00','坐車到大阪日本橋 (移動)','直接坐到大阪近鐵日本橋',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',5,'2026-04-08','7c1dc5a6-1952-4a38-83d6-e067cf65d9a8','7c1dc5a6-1952-4a38-83d6-e067cf65d9a8',0,6,'20:00',NULL,'日本環球影城 利蓓薾酒店 (住宿)','步行350m>惠美須町>堺筋線(1站)>動物園前 新今宮>大阪環狀線(5站)>西九條車站 >ＪＲ夢咲線(3站)>櫻島車站 步行550m(38min)','https://maps.app.goo.gl/cMMDBAhnmgih6aYT6'),

-- Day 6
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',6,'2026-04-09','f6492351-e28e-47c8-a33f-873b87e11539','f6492351-e28e-47c8-a33f-873b87e11539',0,0,'06:00','7:30','起床 (作業)','6:00起床 7:30出門',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',6,'2026-04-09','a60741e3-2041-412a-a5e5-15928ee9d631','a60741e3-2041-412a-a5e5-15928ee9d631',0,1,'09:00','18:00','環球影城 (吃喝)','9:00-10:00 好來塢美夢(先去排)/太空幻想列車/買柯南犯人娃娃 10:00-11:30 咚其剛跟馬力歐(2快通加拍照) 11:30 吃飯 12:30-13:00 水世界（來不及就先去玩太空幻想列車） 14:15~16:20 柯南密室團脫(買柯南犯人娃娃) 16:30飛天異龍or侏儸紀 17:00 太空幻想列車OR小小兵瘋狂乘車遊or水世界 18:00 哈利波特 18:30 買紀念品（18:15妖魔鬼怪搖滾樂表演秀','https://maps.app.goo.gl/SXhRz36NhxqWCTYr9'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',6,'2026-04-09',gen_random_uuid(),gen_random_uuid(),0,8,'09:00','18:00','環球影城 (餐點)','Mario Cafe & Store™(可用手機點餐) (賣鬆餅蛋糕跟可愛杯子飲料) 奇諾比奧咖啡店(有賣正餐)(有手機點餐) 親善碼頭餐廳(有賣正餐)(有手機點餐) 史努比外景咖啡廳(有賣正餐)(有手機點餐)',NULL),

-- Day 7
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10','2e720613-77cb-4b64-9aa1-52a75c52f9c8','2e720613-77cb-4b64-9aa1-52a75c52f9c8',0,0,'09:00','10:00','起床 (作業)','9:00起床 10:00出門',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10','36d1f991-b09c-4380-b27b-c5019c8db626','36d1f991-b09c-4380-b27b-c5019c8db626',0,1,'10:00','11:00','去日航飯店放行李(40min)','地鐵 櫻島車站>ＪＲ夢咲線(3站)(大阪環狀線)(3站)>大阪車站 梅田>(御堂筋線)4站>心齋橋站','https://maps.app.goo.gl/CPNFYi7WoNngxDJL6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10',gen_random_uuid(),gen_random_uuid(),0,8,'12:00','13:00','吃午餐(~とんかつ 豚しゃぶ 樋ぞの)','hizonoとんかつ 豚しゃぶ 樋ぞの  訂位12:00','https://maps.app.goo.gl/HrfWtLXpWWebot3Q9'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10','4e07d260-4220-4fdc-a0fe-b916e6703b3d','4e07d260-4220-4fdc-a0fe-b916e6703b3d',0,3,'13:30','15:00','造幣局櫻花通道 (景點)','西大橋>長堀鶴見綠地線(8站)>京橋（大阪）>步行1km 預約13:30-14:00，qrcode 入場','https://maps.app.goo.gl/HKWKohwKky6qxcZ59'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10','2194b1ed-fb22-4bc0-b8bf-931cff2c8163','2194b1ed-fb22-4bc0-b8bf-931cff2c8163',0,4,NULL,NULL,'大阪城 (景點)','心齋橋站>長堀鶴見綠地線(6站)>大阪商務園區 步行900m 天守閣門票 kkday$241','https://maps.app.goo.gl/7VGgnqFo63ZbbQJK8'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10','e42fdc50-b6e0-4bf8-9b33-e970987a5ff4','e42fdc50-b6e0-4bf8-9b33-e970987a5ff4',0,5,NULL,NULL,'回到心齋橋逛街 (景點)','天滿橋>谷町線(2站)>東梅田 梅田>御堂筋線(3站)>心齋橋站 固力果 https://maps.app.goo.gl/xcoX97HJj2gGwFHe8 章魚燒甲賀流 アメリカ村本店 https://maps.app.goo.gl/pj4ZaG4fQHi6tWF89 美國村',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10','7093a30e-f47c-4dd3-840e-15e04c16b9eb','7093a30e-f47c-4dd3-840e-15e04c16b9eb',0,6,'19:15',NULL,'吃晚餐-(焼肉力丸心齋橋店)','訂位19:15','https://maps.app.goo.gl/iCPYnUroqbzFQeU99'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',7,'2026-04-10','ce134d7f-af3b-44e6-adae-2cb443bc48e4','ce134d7f-af3b-44e6-adae-2cb443bc48e4',0,7,NULL,NULL,'大阪日航酒店 (住宿)',NULL,'https://maps.app.goo.gl/CPNFYi7WoNngxDJL6'),

-- Day 8
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11','d299e13b-1c09-4947-885f-a40ab6b8d984','d299e13b-1c09-4947-885f-a40ab6b8d984',0,0,'07:30','9:00','起床 (作業)','9:00出門',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11','0ce2492b-d8ef-4771-b290-c1aa049b0ae4','0ce2492b-d8ef-4771-b290-c1aa049b0ae4',0,1,NULL,NULL,'早餐 (吃喝)',NULL,NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11','9bfde440-efc1-46ca-913f-467570bfc817','9bfde440-efc1-46ca-913f-467570bfc817',0,2,NULL,NULL,'梅田逛街','寶可夢中心 大阪大丸梅田店13f https://maps.app.goo.gl/vMmeTuP61MCaWLS38 はなだこ章魚燒 https://maps.app.goo.gl/EiDsNpE7KbtDPL4f6','https://maps.app.goo.gl/BkmBXtg9wDZQTsye6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11','19e8c6a7-63ca-486f-ae8c-e12e8c8f0a6a','19e8c6a7-63ca-486f-ae8c-e12e8c8f0a6a',0,3,NULL,NULL,'午餐-すき焼 しゃぶしゃぶつかだ KITTE大阪','好好吃的壽喜燒 也可以吃別的qwq','https://maps.app.goo.gl/SJ7kUYC6icSxGpKs6'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11','c3355099-22ee-4711-baf3-301de1e285e7','c3355099-22ee-4711-baf3-301de1e285e7',0,4,NULL,NULL,'HEP FIVE、中崎町','逛逛逛 中崎町 懷舊雜物小店 動物雑貨ONLY PLANET https://maps.app.goo.gl/FekL8M243FPjwM1y5 日本柑仔店Horiike https://maps.app.goo.gl/sZiUMsxvLvCc8wWr6 kaju_0808(飾品) 天五中崎通商店街(可搭谷町線一站地鐵過去)或走過去 https://maps.app.goo.gl/EqdFDBfJzTdTC76GA',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11',gen_random_uuid(),gen_random_uuid(),0,8,NULL,NULL,'咖啡廳neel nakazakicho','奶油糖霜薄可餅 備選 cafe太陽ノ塔 本店 https://maps.app.goo.gl/M1hT7THFScBAuPYJ7 OSA COFFEE https://maps.app.goo.gl/BN8rASkUKoPp2o5CA MARK COFFEE ROASTERS https://maps.app.goo.gl/Qfcj6Sah8GgY5qEG9','https://maps.app.goo.gl/XAYJXUMR5CWiMe769'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11',gen_random_uuid(),gen_random_uuid(),0,8,NULL,NULL,'晚餐-すし酒場 さしす','すし酒場 さしす','https://maps.app.goo.gl/n7bM5YK85uB7murMA'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',8,'2026-04-11','e5e4eff8-1c42-44b3-80df-81cdd08042e8','e5e4eff8-1c42-44b3-80df-81cdd08042e8',0,7,NULL,NULL,'大阪日航酒店 (住宿)',NULL,'https://maps.app.goo.gl/CPNFYi7WoNngxDJL6'),

-- Day 9
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',9,'2026-04-12','fccfffa6-b280-413e-9643-7b8c40465b91','fccfffa6-b280-413e-9643-7b8c40465b91',0,0,'06:10','7:00','起床 (作業)','6:10起床 7:00出門',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',9,'2026-04-12','379ad8f7-1f94-4e14-838c-4ce7d1567363','379ad8f7-1f94-4e14-838c-4ce7d1567363',0,1,'10:45',NULL,'航班 MM031 (移動)','7:00 心齋橋站>御堂筋線(1站)>難波站 南海難波>ＲＡＰＩＴα 7>關西機場 8:15到機場 要到第二航廈 10:45>(MM031)>13:10',NULL),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',9,'2026-04-12','845dcdaa-d594-4608-a0d2-a387e4081545','845dcdaa-d594-4608-a0d2-a387e4081545',0,2,NULL,NULL,'往勝尾寺','大國町站>御堂筋線(10站)北大阪急行線(5站)>箕面萱野站 巴士：「箕面萱野站 阪急巴士8號乘車處」出發 箕面萱野站 → 勝尾寺','https://maps.app.goo.gl/kPs23DVxUTNUEAtW7'),
('a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',9,'2026-04-12','6f3911a0-f975-4d78-aa20-662dcf6937c7','6f3911a0-f975-4d78-aa20-662dcf6937c7',0,3,NULL,NULL,'大阪日航酒店 (住宿)',NULL,'https://maps.app.goo.gl/CPNFYi7WoNngxDJL6'),

-- 濟州旅程 Day 1-6
('a4fd9d5b-4c38-4101-ba22-cd80369da12b',1,'2027-01-08','4de59810-2b28-41c0-8d98-2ccbfb15dbec','4de59810-2b28-41c0-8d98-2ccbfb15dbec',0,0,NULL,NULL,'（待新增）',NULL,NULL),
('a4fd9d5b-4c38-4101-ba22-cd80369da12b',2,'2027-01-09','da6b4fe7-f013-4647-9787-b90b93623061','da6b4fe7-f013-4647-9787-b90b93623061',0,0,NULL,NULL,'（待新增）',NULL,NULL),
('a4fd9d5b-4c38-4101-ba22-cd80369da12b',3,'2027-01-10','89977dae-02d5-476a-88bf-5ea91b90639e','89977dae-02d5-476a-88bf-5ea91b90639e',0,0,NULL,NULL,'（待新增）',NULL,NULL),
('a4fd9d5b-4c38-4101-ba22-cd80369da12b',4,'2027-01-11','bb6ffc20-e378-424e-bf22-2a2137218b9d','bb6ffc20-e378-424e-bf22-2a2137218b9d',0,0,NULL,NULL,'（待新增）',NULL,NULL),
('a4fd9d5b-4c38-4101-ba22-cd80369da12b',5,'2027-01-12','a16b52b5-a7bf-4ff8-8ec9-a2c711ad3301','a16b52b5-a7bf-4ff8-8ec9-a2c711ad3301',0,0,NULL,NULL,'（待新增）',NULL,NULL),
('a4fd9d5b-4c38-4101-ba22-cd80369da12b',6,'2027-01-13','43b85a52-c822-4784-8984-c428af807fc9','43b85a52-c822-4784-8984-c428af807fc9',0,0,NULL,NULL,'（待新增）',NULL,NULL);
