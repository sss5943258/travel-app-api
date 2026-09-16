-- ============================================================
-- seed.sql  |  100% 同步自 Google 試算表完整資料
-- ============================================================

-- 建立 UUID extension (若尚未建立)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 0. 建立資料表結構 (DDL Schema)
-- ============================================================

-- 1. Trips 主表
CREATE TABLE IF NOT EXISTS "Trips" (
    "TripId" uuid NOT NULL,
    "ReadOnlyId" uuid NOT NULL,
    "Name" character varying(200) NOT NULL,
    "StartDate" text,
    "EndDate" text,
    "CoverUrl" text,
    "UserId" text,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT "PK_Trips" PRIMARY KEY ("TripId")
);
ALTER TABLE "Trips" ADD COLUMN IF NOT EXISTS "UserId" text;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Trips_ReadOnlyId" ON "Trips" ("ReadOnlyId");
CREATE INDEX IF NOT EXISTS "IX_Trips_UserId" ON "Trips" ("UserId");

-- 2. Users 使用者表 (Google OAuth)
CREATE TABLE IF NOT EXISTS "Users" (
    "UserId" character varying(100) NOT NULL,
    "Email" character varying(200) NOT NULL,
    "Name" character varying(200) NOT NULL,
    "Picture" text,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    "LastLoginAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT "PK_Users" PRIMARY KEY ("UserId")
);
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Users_Email" ON "Users" ("Email");

-- 3. UserSessions 登入階段表 (RefreshToken)
CREATE TABLE IF NOT EXISTS "UserSessions" (
    "SessionId" uuid NOT NULL,
    "UserId" character varying(100) NOT NULL,
    "RefreshToken" text NOT NULL,
    "RefreshExpiresAt" timestamp with time zone NOT NULL,
    "IsRevoked" boolean NOT NULL DEFAULT FALSE,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT "PK_UserSessions" PRIMARY KEY ("SessionId"),
    CONSTRAINT "FK_UserSessions_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("UserId") ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS "IX_UserSessions_RefreshToken" ON "UserSessions" ("RefreshToken");

-- 4. TripCollaborators 旅程共編者表
CREATE TABLE IF NOT EXISTS "TripCollaborators" (
    "TripId" uuid NOT NULL,
    "UserEmail" character varying(200) NOT NULL,
    "Role" character varying(50) NOT NULL DEFAULT 'editor',
    "AddedAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT "PK_TripCollaborators" PRIMARY KEY ("TripId", "UserEmail"),
    CONSTRAINT "FK_TripCollaborators_Trips_TripId" FOREIGN KEY ("TripId") REFERENCES "Trips" ("TripId") ON DELETE CASCADE
);

-- 5. UploadedImages 圖片持久化表 (Neon DB BYTEA)
CREATE TABLE IF NOT EXISTS "UploadedImages" (
    "ImageId" uuid NOT NULL,
    "TripId" uuid,
    "ContentType" character varying(50) NOT NULL DEFAULT 'image/png',
    "FileName" text,
    "Data" bytea NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT "PK_UploadedImages" PRIMARY KEY ("ImageId")
);

-- 6. TripInfos 表 (1對1 關聯 Trips)
CREATE TABLE IF NOT EXISTS "TripInfos" (
    "TripId" uuid NOT NULL,
    "OutboundFlightNo" text,
    "OutboundAirline" text,
    "OutboundDepartureTime" text,
    "OutboundArrivalTime" text,
    "OutboundDepAirport" text,
    "OutboundArrAirport" text,
    "OutboundFlightRemark" text,
    "OutboundImageUrl" text,
    "InboundFlightNo" text,
    "InboundAirline" text,
    "InboundDepartureTime" text,
    "InboundArrivalTime" text,
    "InboundDepAirport" text,
    "InboundArrAirport" text,
    "InboundFlightRemark" text,
    "InboundImageUrl" text,
    "TripRemark" text,
    CONSTRAINT "PK_TripInfos" PRIMARY KEY ("TripId"),
    CONSTRAINT "FK_TripInfos_Trips_TripId" FOREIGN KEY ("TripId") REFERENCES "Trips" ("TripId") ON DELETE CASCADE
);

-- 7. Schedules 表 (行程明細)
CREATE TABLE IF NOT EXISTS "Schedules" (
    "Id" uuid NOT NULL,
    "TripId" uuid NOT NULL,
    "GroupId" uuid NOT NULL,
    "Day" integer NOT NULL,
    "Date" text,
    "AltOrder" integer NOT NULL DEFAULT 0,
    "SortOrder" integer NOT NULL DEFAULT 0,
    "AttractionName" character varying(300) NOT NULL,
    "StartTime" text,
    "EndTime" text,
    "Remark" text,
    "GoogleMapLink" text,
    "ImageUrl" text,
    CONSTRAINT "PK_Schedules" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Schedules_Trips_TripId" FOREIGN KEY ("TripId") REFERENCES "Trips" ("TripId") ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS "IX_Schedules_TripId_Day_SortOrder" ON "Schedules" ("TripId", "Day", "SortOrder");

-- 8. PackingItems 表 (行李清單)
CREATE TABLE IF NOT EXISTS "PackingItems" (
    "ItemId" uuid NOT NULL,
    "Name" character varying(200) NOT NULL,
    "IsEssential" boolean NOT NULL DEFAULT FALSE,
    "Checked" boolean NOT NULL DEFAULT FALSE,
    "SortOrder" integer NOT NULL DEFAULT 0,
    "UserId" text,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT "PK_PackingItems" PRIMARY KEY ("ItemId")
);
ALTER TABLE "PackingItems" ADD COLUMN IF NOT EXISTS "UserId" text;
CREATE INDEX IF NOT EXISTS "IX_PackingItems_UserId" ON "PackingItems" ("UserId");

-- ============================================================
-- 1. Users 資料 (登入者與共編者帳號)
-- ============================================================
INSERT INTO "Users" ("UserId", "Email", "Name", "Picture", "CreatedAt", "LastLoginAt")
VALUES
(
  '105676405736689549097',
  'sss5943258@gmail.com',
  'Raki C',
  'https://lh3.googleusercontent.com/a/ACg8ocIS19_4bFpUfD965gO1kFv9bBqH7YFmG8f6fN3y=s96-c',
  '2026-09-12 07:14:56.846+00',
  NOW()
),
(
  '110443873207923725515',
  'zzz5943258@gmail.com',
  '莊孟勳',
  NULL,
  '2026-09-14 07:09:21.250+00',
  '2026-09-14 07:09:21.250+00'
),
(
  '112689254923581781254',
  'q7519470@gmail.com',
  '陳昀璟',
  NULL,
  '2026-09-14 16:52:14.726+00',
  '2026-09-14 16:52:14.726+00'
)
ON CONFLICT ("UserId") DO UPDATE SET
  "Email" = EXCLUDED."Email",
  "Name" = EXCLUDED."Name",
  "Picture" = COALESCE(EXCLUDED."Picture", "Users"."Picture"),
  "LastLoginAt" = EXCLUDED."LastLoginAt";

-- ============================================================
-- 2. UserSessions 資料 (範例會話與 RefreshToken)
-- ============================================================
INSERT INTO "UserSessions" ("SessionId", "UserId", "RefreshToken", "RefreshExpiresAt", "IsRevoked", "CreatedAt")
VALUES
(
  '4ba19496-b089-4933-a3d1-419b4cfb0766',
  '105676405736689549097',
  '1b657f09-c5ec-448a-bf90-3cb83ed81d48',
  '2026-10-12 07:14:56.846+00',
  TRUE,
  '2026-09-12 07:14:56.846+00'
),
(
  'e7e721ae-b80a-4c8e-a2b1-123456789abc',
  '105676405736689549097',
  '22c7991d-a86d-4b92-8051-abcdef123456',
  NOW() + INTERVAL '30 days',
  FALSE,
  NOW()
)
ON CONFLICT ("SessionId") DO UPDATE SET
  "RefreshToken" = EXCLUDED."RefreshToken",
  "RefreshExpiresAt" = EXCLUDED."RefreshExpiresAt",
  "IsRevoked" = EXCLUDED."IsRevoked";

-- ============================================================
-- 3. Trips 資料 (3 筆旅程)
-- ============================================================
INSERT INTO "Trips" ("TripId", "ReadOnlyId", "Name", "StartDate", "EndDate", "CoverUrl", "UserId", "CreatedAt")
VALUES
(
  'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15',
  '9b4e1d72-3a0f-4c8e-a293-5f7b6e2d0a84',
  '🌸 2026 京阪名古屋大拇指櫻花季',
  '2026-04-04',
  '2026-04-12',
  'https://images.unsplash.com/photo-1522273400909-fd1a8f77637e',
  '105676405736689549097',
  NOW()
),
(
  '2e18e026-036a-4410-be83-06d7dc2864ab',
  'ae771a37-2f86-4006-a1aa-fd0c9225a20b',
  '升等撒撒給油',
  '2026-08-12',
  '2026-08-16',
  NULL,
  '105676405736689549097',
  NOW()
),
(
  '34fa3576-22c7-4ac6-93bf-5ec58658bfe3',
  '2b256d84-34fa-4ac6-93bf-5ec58658bfe3',
  '濟州哈些優',
  '2027-01-07',
  '2027-01-12',
  NULL,
  '105676405736689549097',
  NOW()
)
ON CONFLICT ("TripId") DO UPDATE SET
  "Name" = EXCLUDED."Name",
  "StartDate" = EXCLUDED."StartDate",
  "EndDate" = EXCLUDED."EndDate",
  "CoverUrl" = EXCLUDED."CoverUrl",
  "UserId" = EXCLUDED."UserId";

-- ============================================================
-- 2. TripInfos 資料 (3 筆航班與備註)
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
),
(
  '2e18e026-036a-4410-be83-06d7dc2864ab',
  'UA838', '聯合航空', '2026-08-12 9:55', '2026-08-12 14:55',
  'KHH', 'NRT', '區間車永康6:06出發',
  'https://drive.google.com/thumbnail?id=1x9sdnIjBe3i0tvMf__A0SgQX5VUJuRgv&sz=w1000',
  'UA837', '聯合航空', '2026-08-16 17:55', '2026-08-16 21:00',
  'NRT', 'KHH', NULL,
  'https://drive.google.com/thumbnail?id=1beb2C5Lhhi_Ag9uVA2WZuE5Fcw7dGeqB&sz=w1000',
  NULL
),
(
  '34fa3576-22c7-4ac6-93bf-5ec58658bfe3',
  'IT654', '虎航', '2027-01-07 6:40', '2027-01-07 9:50',
  'TPE', 'CJU', NULL,
  'https://drive.google.com/thumbnail?id=1SN7tIOSQ4RkqtZL0LNBkURrnagN6jqG9&sz=w1000',
  'IT655', '虎航', '2027-01-12 11:00', '2027-01-12 12:15',
  'CJU', 'TPE', NULL,
  'https://drive.google.com/thumbnail?id=1MUtH-jGVky9qd1AKTUnJmRcGnr07csIm&sz=w1000',
  NULL
)
ON CONFLICT ("TripId") DO UPDATE SET
  "OutboundFlightNo" = EXCLUDED."OutboundFlightNo",
  "OutboundAirline" = EXCLUDED."OutboundAirline",
  "OutboundDepartureTime" = EXCLUDED."OutboundDepartureTime",
  "OutboundArrivalTime" = EXCLUDED."OutboundArrivalTime",
  "OutboundDepAirport" = EXCLUDED."OutboundDepAirport",
  "OutboundArrAirport" = EXCLUDED."OutboundArrAirport",
  "OutboundFlightRemark" = EXCLUDED."OutboundFlightRemark",
  "OutboundImageUrl" = EXCLUDED."OutboundImageUrl",
  "InboundFlightNo" = EXCLUDED."InboundFlightNo",
  "InboundAirline" = EXCLUDED."InboundAirline",
  "InboundDepartureTime" = EXCLUDED."InboundDepartureTime",
  "InboundArrivalTime" = EXCLUDED."InboundArrivalTime",
  "InboundDepAirport" = EXCLUDED."InboundDepAirport",
  "InboundArrAirport" = EXCLUDED."InboundArrAirport",
  "InboundFlightRemark" = EXCLUDED."InboundFlightRemark",
  "InboundImageUrl" = EXCLUDED."InboundImageUrl",
  "TripRemark" = EXCLUDED."TripRemark";

-- ============================================================
-- 3. PackingItems 資料 (5 筆行李品項)
-- ============================================================
INSERT INTO "PackingItems" ("ItemId", "Name", "IsEssential", "Checked", "SortOrder", "UserId", "CreatedAt")
VALUES
  ('e888879c-6e4b-44b7-84fc-635c3fe0fff3', '護照',     TRUE,  FALSE, 1, '105676405736689549097', '2026-07-01 20:42:57+00'),
  ('ea5c053b-9b06-4185-8fb4-53093fdde5f4', '錢包',     TRUE,  FALSE, 2, '105676405736689549097', '2026-07-01 20:43:17+00'),
  ('351b3052-4d8a-45a0-894b-aaaa2c8eebaa', '墨鏡',     FALSE, TRUE,  3, '105676405736689549097', '2026-07-01 20:43:28+00'),
  ('9b8ca65e-04b8-4707-a0a1-4b68ae0c778a', '御朱印帳', FALSE, FALSE, 4, '105676405736689549097', '2026-07-01 20:44:01+00'),
  ('fa49db31-a24f-4d69-be54-c9f57dfc1fb2', '髮品',     FALSE, TRUE,  5, '105676405736689549097', NOW())
ON CONFLICT ("ItemId") DO UPDATE SET
  "Name" = EXCLUDED."Name",
  "IsEssential" = EXCLUDED."IsEssential",
  "Checked" = EXCLUDED."Checked",
  "SortOrder" = EXCLUDED."SortOrder",
  "UserId" = EXCLUDED."UserId";

-- ============================================================
-- 4. Schedules 資料 (共 109 筆行程明細)
-- ============================================================
INSERT INTO "Schedules" ("Id", "TripId", "GroupId", "Day", "Date", "AltOrder", "SortOrder", "StartTime", "EndTime", "AttractionName", "Remark", "GoogleMapLink", "ImageUrl")
VALUES
('d34bc84a-c0fc-413b-9fe8-f0c8f306d1e4', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'd34bc84a-c0fc-413b-9fe8-f0c8f306d1e4', 1, '2026-04-04', 0, 0, '23:30', NULL, '家→台北 (移動)', '桃機第一航廈', NULL, NULL),
('52033599-fd10-477c-8fbd-1af249a5fee7', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '52033599-fd10-477c-8fbd-1af249a5fee7', 1, '2026-04-04', 0, 1, '02:10', '06:00', '航班 MM722 (移動)', '23:30到機場, 1:55飛機-5:45到名古屋', NULL, NULL),
('bde0acd9-cfee-4a8b-a8ff-c6b519a16574', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'bde0acd9-cfee-4a8b-a8ff-c6b519a16574', 1, '2026-04-04', 0, 2, '07:00', NULL, '出關、買名鐵車票 (景點)', '7:00出關 名鐵線(μ－ＳＫＹ) 中部國際機場>(3站)>名鐵名古屋>步行550m到飯店(35min) Montblanc Hotel Raffine Nagoya Ekimae モンブランホテルラフィネ名古屋駅前 https://maps.app.goo.gl/884amAjLevuB6kQ57 放行李', NULL, NULL),
('1a69f4bb-615b-4091-96f1-14e2fcac34df', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '1a69f4bb-615b-4091-96f1-14e2fcac34df', 1, '2026-04-04', 0, 3, NULL, NULL, '飯店寄行李 (作業)', 'Montblanc Hotel Raffine Nagoya Ekimae', 'https://maps.app.goo.gl/XQ1yWjgKgRHJfAxr7', NULL),
('71aefdd1-7b36-4851-9b32-97aee0711b6c', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '71aefdd1-7b36-4851-9b32-97aee0711b6c', 1, '2026-04-04', 0, 4, '10:30', NULL, '早餐~天然酵母の食パン専門店 つばめパン＆Milk 名駅店', '去趣寫(禮拜六沒開)但官網跟google寫有營業 上午 8:00-11:00 要抽號碼牌 https://tsubamepan.jp/waiting/ (等待人數跟時間可以查) 離飯店850 公尺', 'https://maps.app.goo.gl/B1dvkCkZczTVLYtU8', NULL),
('0c874952-0711-4f59-8707-31b9e412eb8e', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '0c874952-0711-4f59-8707-31b9e412eb8e', 1, '2026-04-04', 0, 5, '11:30', NULL, '熱田神宮 (景點)', '9:30 (要記得在名古屋車站買一日票) 自動販賣機販售地下鉄全線24時間券￥760、週末環保票成人620日元(不能乘坐Yurorito Line高架區間（大曽根～小幡緑地）以及名鐵巴士、青波線。) 步行400m> 名鐵名古屋>名鐵常滑線(急行)1站>金山（愛知） 金山>名城線(3站)>熱田神宮傳馬町一號出口 9:50到 要吃鰻魚飯就坐到傳馬町(靠近南門和熱田蓬萊軒)，先抽鰻魚飯號碼牌 從南門走到本殿就要走將近10分鐘', 'https://maps.app.goo.gl/L51wJvmCGvC2MTB99', NULL),
('b70562fe-635b-4a77-8d29-eea2a16cb1ad', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'b70562fe-635b-4a77-8d29-eea2a16cb1ad', 1, '2026-04-04', 0, 6, '11:30', NULL, '午餐熱田蓬萊軒 本店 (吃喝)', '可先抽號碼牌', 'https://maps.app.goo.gl/kFbAG2baPHBppFk59', NULL),
('5cab5e8c-1db7-4e0a-afba-1d5d3f56fd2e', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '5cab5e8c-1db7-4e0a-afba-1d5d3f56fd2e', 1, '2026-04-04', 0, 7, '14:30', NULL, '鶴舞公園看櫻花 (景點)', '熱田神宮傳馬町>名城線(5站)>上前津車站 上前津車站>鶴舞線(1站)>鶴舞車站 180m到公園 36min', 'https://maps.app.goo.gl/3PQfkL92HFAzZLKc7', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 1, '2026-04-04', 0, 7, '22:00', NULL, 'Montblanc Hotel Raffine Nagoya Ekimae', NULL, 'https://maps.app.goo.gl/XQ1yWjgKgRHJfAxr7', NULL),
('8823b9f8-2945-428d-a6e2-942e30d5f106', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '8823b9f8-2945-428d-a6e2-942e30d5f106', 1, '2026-04-04', 0, 9, '16:30', NULL, '回名鐵名古屋(吃甜點or回去休息)', '回名鐵名古屋 鶴舞車站>(JR)中央本線(2站)>名古屋車站(17MIN) HARBS 名鐵名古屋店 https://maps.app.goo.gl/7tUL2HT7RW1NzFds7 (飯店)Montblanc Hotel Raffine Nagoya Ekimae https://maps.app.goo.gl/884amAjLevuB6kQ57', 'https://maps.app.goo.gl/LDQiQvFTnddaxk5z5', NULL),
('377f3fc9-e704-46d0-86d6-308c7ab880d5', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '377f3fc9-e704-46d0-86d6-308c7ab880d5', 1, '2026-04-04', 0, 10, '18:30', NULL, '榮商圈、唐吉軻德逛街', '名古屋車站>東山線(2站)>榮（愛知）', 'https://maps.app.goo.gl/bNUWsPXg4ixVWQrG6', NULL),
('bdead5ee-2d42-4507-9445-9bcee579720b', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'bdead5ee-2d42-4507-9445-9bcee579720b', 1, '2026-04-04', 0, 11, '19:00', NULL, '晚餐~ほるたん屋 栄店(訂位19:00)', NULL, 'https://maps.app.goo.gl/xzT9iAQSQBdZ41TGA', NULL),
('6b3fbb4b-f356-4319-848d-63ece7825248', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '6b3fbb4b-f356-4319-848d-63ece7825248', 2, '2026-04-05', 0, 0, '07:00', NULL, '起床、早餐 (作業)', '9:30出門、退房寄放行李', NULL, NULL),
('a922765b-6ce8-4b92-bd9f-74effe219cbf', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'a922765b-6ce8-4b92-bd9f-74effe219cbf', 2, '2026-04-05', 0, 1, '11:00', NULL, '京都Emion飯店 (住宿)', '放行李', 'https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7', NULL),
('68d4af29-0eaf-4467-9365-78edc97b679d', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'a922765b-6ce8-4b92-bd9f-74effe219cbf', 2, '2026-04-05', 1, 1, '11:00', NULL, 'test被按2', NULL, NULL, NULL),
('0b7f3f7a-a40a-4f05-8188-25a40272c759', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '0b7f3f7a-a40a-4f05-8188-25a40272c759', 2, '2026-04-05', 0, 2, NULL, NULL, '坐車到京都(45分) (移動)', '名古屋車站>新幹線(1站)>京都車站 到飯店放行李 京都車站>山陰本線(1站)>梅小路京都西>步行350 公尺(7min) 京都Emion飯店 https://maps.app.goo.gl/NYbVWLKFBZFJRPTcA 11:00放行李', 'https://maps.app.goo.gl/LDQiQvFTnddaxk5z5', NULL),
('87935343-9ccc-4783-b741-922654738b90', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '87935343-9ccc-4783-b741-922654738b90', 2, '2026-04-05', 0, 3, '11:30', NULL, '河原町吃午餐', '吃什麼再找', 'https://maps.app.goo.gl/kXDhbMaPwWvX7UtS8', NULL),
('3ce63fe4-4654-48ee-ad53-62747dbd3f3e', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '3ce63fe4-4654-48ee-ad53-62747dbd3f3e', 2, '2026-04-05', 0, 4, '13:00', NULL, '下鴨神社 (景點)', '三條（京都）>京阪本線(2站)>出町柳 下鴨神社春有櫻花御守 https://maps.app.goo.gl/AzMsovybAEP8RiqR7 ', 'https://maps.app.goo.gl/XEWdCvWdhrF6wdcj8', NULL),
('2b395673-46cf-4174-af13-7079e2fe4438', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '2b395673-46cf-4174-af13-7079e2fe4438', 2, '2026-04-05', 0, 5, '15:00', '20:00', '逛街(河原町、四條) (景點)', '出町柳>京阪本線(2站)>三條（京都） 15:00~19:00 Kawaramachi OPA https://maps.app.goo.gl/gbfFP8FFzzGc95Ww9 各種百貨公司', 'https://maps.app.goo.gl/38W1vSeA6JdgmooYA', NULL),
('77a1e8d5-6b2f-46fd-bf22-d52027a05704', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '77a1e8d5-6b2f-46fd-bf22-d52027a05704', 2, '2026-04-05', 0, 6, NULL, NULL, '京都Emion飯店 (住宿)', '四條>烏丸線(2站)>京都車站>山陰本線(1站)>梅小路京都西', 'https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 2, '2026-04-05', 0, 7, '13:00', NULL, '河合神社', '河合神社 https://maps.app.goo.gl/JkjYnHYZNhUozLeEA 求「美麗」的神社', 'https://maps.app.goo.gl/Pwh6v3HH9Vwx6ZgU6', NULL),
('4e6e7d20-0a6f-48ff-be02-890db0b24e3c', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '4e6e7d20-0a6f-48ff-be02-890db0b24e3c', 2, '2026-04-05', 0, 8, '20:00', '21:30', '和牛すき焼き京都ぱんが', '預約20:00', 'https://maps.app.goo.gl/GvyXFj3yjo4ATAHTA', NULL),
('655f417a-925c-46ab-9764-637091db7e26', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '655f417a-925c-46ab-9764-637091db7e26', 2, '2026-04-05', 0, 9, NULL, NULL, 'test被按', NULL, NULL, NULL),
('62488270-1305-4efc-afbb-faeb795b5586', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '62488270-1305-4efc-afbb-faeb795b5586', 3, '2026-04-06', 0, 0, '06:30', NULL, '起床 (作業)', '6:30起床 7:45出門', NULL, NULL),
('a6b0fb0e-4382-42c4-aea7-5b3091fed477', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'a6b0fb0e-4382-42c4-aea7-5b3091fed477', 3, '2026-04-06', 0, 1, '08:30', NULL, 'mocomoco和服店換裝 (作業)', '京都車站>市營巴206 City Bus(8站)>五条坂 步行78m(24分) 預約8:30 https://maps.app.goo.gl/v42cSPKDQNRVBrG79 可放行李 五點半前還衣服(可跨店還) (清水寺店、嵐山店、八坂神社店、伏見稻荷店)', 'https://maps.app.goo.gl/pRcqpQ69z1swfEHS6', NULL),
('5807a417-9820-4a20-bc58-30abde2b4510', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '5807a417-9820-4a20-bc58-30abde2b4510', 3, '2026-04-06', 0, 2, '10:00', NULL, '清水寺 (景點)', '10:00到 早上6:00至下午6:00 500yen入園費', 'https://maps.app.goo.gl/jxBvCuTYqRJv7nF5A', NULL),
('5d628d4e-613e-4618-a27d-e86e207ad8a3', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '5d628d4e-613e-4618-a27d-e86e207ad8a3', 3, '2026-04-06', 0, 3, '11:45', NULL, '安井金比羅宮 (景點)', '從清水寺走900m 無論是健康、情感、習慣、人際關係或業障上的「緣」，信眾皆可前來祈求「斷惡緣、結善緣」 https://maps.app.goo.gl/uBbS9hzchVBZTxxP7 八坂庚申堂 經過可去(柯南聖地巡禮)', 'https://maps.app.goo.gl/3Z5TBfjHnkvVNvsM7', NULL),
('c2ba3976-3a11-47e7-b777-3dbc8c8ae5fe', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'c2ba3976-3a11-47e7-b777-3dbc8c8ae5fe', 3, '2026-04-06', 0, 4, '11:30', NULL, '午餐~らーめん錦 (吃喝)', '抹茶拉麵', 'https://maps.app.goo.gl/6XnUEDNEjhQnDK5A9', NULL),
('163511f0-d526-4dbf-a1a5-f8f582a6b63a', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '163511f0-d526-4dbf-a1a5-f8f582a6b63a', 3, '2026-04-06', 0, 5, NULL, NULL, '八坂神社 (景點)', '再走600m 門票免費 花見小路通', 'https://maps.app.goo.gl/3Z5TBfjHnkvVNvsM7', NULL),
('f07dc8ea-960e-498c-9a0f-15b8aeeaf04a', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'f07dc8ea-960e-498c-9a0f-15b8aeeaf04a', 3, '2026-04-06', 0, 6, NULL, NULL, '下午茶-甘味どころ ぎをん 小森 (吃喝)', '宇治金時, (還和服)', 'https://maps.app.goo.gl/chF89oaqW5z1SxEW7', NULL),
('31004772-64a4-46e9-b959-ccc832a14272', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '31004772-64a4-46e9-b959-ccc832a14272', 3, '2026-04-06', 0, 7, NULL, NULL, '還和服 (作業)', '八坂神社 祇園>202、206、207 City Bus>清水道(2站)', 'https://maps.app.goo.gl/pRcqpQ69z1swfEHS6', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 3, '2026-04-06', 0, 7, NULL, NULL, '伏見稻荷大社(看累不累決定', '千本鳥居 狐狸御守很可愛 到山頂大概是40-50樓', 'https://maps.app.goo.gl/byFkAzi3k9duFgsJ8', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 3, '2026-04-06', 0, 7, NULL, NULL, '新京極商店街小逛', '昨天沒有逛完的河原町可以繼續逛過去到新京極商店街', 'https://maps.app.goo.gl/65kFo9qPFpes7Azw6', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 3, '2026-04-06', 0, 7, NULL, NULL, '晚餐~京都 炭火串焼 つじや 梅小路北店', '居酒屋 京都 炭火串焼 つじや 梅小路北店 ', 'https://maps.app.goo.gl/kMJpmsKdEvfKEtwL9', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 3, '2026-04-06', 0, 7, NULL, NULL, '京都Emion飯店 (住宿)', NULL, 'https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7', NULL),
('d70d7f6f-58f4-4696-ab6c-89cce3f463c2', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'd70d7f6f-58f4-4696-ab6c-89cce3f463c2', 4, '2026-04-07', 0, 0, '07:00', '8:20', '起床 (作業)', '7:00起床 8:20出門', NULL, NULL),
('897b79fd-a63a-42a3-9e4a-f083ed391cbd', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '897b79fd-a63a-42a3-9e4a-f083ed391cbd', 4, '2026-04-07', 0, 1, '8:20', '09:30', '坐車到平等院 (移動)', '(8:36)梅小路京都西>山陰本線(1站)>京都車站 京都車站>奈良線(8站)>宇治車站>步行650m(50分)', 'https://maps.app.goo.gl/BcrmtFdvWabqG4dY7', NULL),
('25f7a137-76e5-4ffb-8b6c-72053e1969a5', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '25f7a137-76e5-4ffb-8b6c-72053e1969a5', 4, '2026-04-07', 0, 2, '09:30', '11:00', '平等院', '平等院與十圓硬幣合照一下 庭院600日元，鳳凰堂加300日元 鳳凰堂購票在橋旁邊的建物，每20分鐘開放50名參觀 庭園8:30～17:30 鳳凰堂內部參觀＊9:30～16:10 (大概逛1~1.5小時)', 'https://maps.app.goo.gl/SqfuGRM8Gqt5kL1i7', NULL),
('cc67691d-ba25-49c8-b2b7-72c88e07533f', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'cc67691d-ba25-49c8-b2b7-72c88e07533f', 4, '2026-04-07', 0, 3, '11:00', NULL, '午餐-拉麵豬一 (吃喝)', '吃的到第一批的話就吃(11:00) 吃拉麵豬一  (11:00吃)', 'https://maps.app.goo.gl/23mk9VorPosiRyCz7', NULL),
('0e8acaa9-673b-4ade-8d63-7dc827cb5d96', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '0e8acaa9-673b-4ade-8d63-7dc827cb5d96', 4, '2026-04-07', 0, 4, '12:00', NULL, '坐車到任天堂博物館 (移動)', '稻荷車站>奈良線(7站)>ＪＲ小倉 600 公尺(28分)', NULL, NULL),
('e6bc8529-5d2c-43f4-a765-428960f6f2cf', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'e6bc8529-5d2c-43f4-a765-428960f6f2cf', 4, '2026-04-07', 0, 5, '12:00', '12:30', '任天堂博物館 (景點)', '宇治>奈良線(1站)>ＪＲ小倉 步行600m(從拉麵店16min) 要帶護照，現場人員“每個人”都檢查。 10個小金幣可以玩遊戲 在這3hr', 'https://maps.app.goo.gl/fWRSAKgXd1dCjjUs5', NULL),
('5a665c7d-ddb9-4fdc-8036-5b58e274e8cc', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '5a665c7d-ddb9-4fdc-8036-5b58e274e8cc', 4, '2026-04-07', 0, 6, NULL, NULL, '下午茶-中村藤吉本店 (吃喝)', '逛宇治附近的抹茶店', 'https://maps.app.goo.gl/am58gmwf8GDyzaH89', NULL),
('53c7466d-8fd4-4cae-a79a-5c0a42a7de4c', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '53c7466d-8fd4-4cae-a79a-5c0a42a7de4c', 4, '2026-04-07', 0, 7, NULL, NULL, '(備案)哲學之道 (景點)', '時間如果還早 祇園>203 City Bus>銀閣寺道>500m(33分)', 'https://maps.app.goo.gl/PtndWZi1wePTNTRR7', NULL),
('6a1931f5-d1c4-4534-b440-5aeecf7f8195', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '6a1931f5-d1c4-4534-b440-5aeecf7f8195', 4, '2026-04-07', 0, 8, NULL, NULL, '高級飯店-京都Emion飯店 (住宿)', NULL, 'https://maps.app.goo.gl/MyfvLQ5j3ifknJBE7', NULL),
('90d945f9-6695-4848-a6cc-1fd90e217e66', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '90d945f9-6695-4848-a6cc-1fd90e217e66', 5, '2026-04-08', 0, 0, '07:00', '08:00', '起床 (作業)', '8:00出門', NULL, NULL),
('026320fc-7a16-4fc4-8709-22219aab0f00', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '026320fc-7a16-4fc4-8709-22219aab0f00', 5, '2026-04-08', 0, 1, '08:00', '09:20', '去京都車站坐車 (移動)', '梅小路京都西>山陰本線(1站)>京都車站 9:20到京都車站', 'https://maps.app.goo.gl/emg1D2ssznVb2L676', NULL),
('ebb51613-1f13-4512-9178-1243df183f85', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'ebb51613-1f13-4512-9178-1243df183f85', 5, '2026-04-08', 0, 2, '09:40', '19:00', '天橋立、伊根舟屋oneday tour (作業)', '集合時間：9:40 出發時間：9:50(導遊會舉GOGODAY的旗子) 地點：京都站八條口-站前觀光巴士停車場(看到ANANTI招牌後左轉)', NULL, NULL),
('5fe5bf9d-f47d-4295-b474-7fbaaceae158', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '5fe5bf9d-f47d-4295-b474-7fbaaceae158', 5, '2026-04-08', 0, 5, '19:00', '20:00', '坐車到大阪日本橋 (移動)', '直接坐到大阪近鐵日本橋', NULL, NULL),
('7c1dc5a6-1952-4a38-83d6-e067cf65d9a8', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '7c1dc5a6-1952-4a38-83d6-e067cf65d9a8', 5, '2026-04-08', 0, 6, '20:00', NULL, '日本環球影城 利蓓薾酒店 (住宿)', '步行350m>惠美須町>堺筋線(1站)>動物園前 新今宮>大阪環狀線(5站)>西九條車站 >ＪＲ夢咲線(3站)>櫻島車站 步行550m(38min) ', 'https://maps.app.goo.gl/cMMDBAhnmgih6aYT6', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 5, '2026-04-08', 0, 7, '09:40', '19:00', '天橋立、智恩寺', '天橋立特有打卡姿勢，從大腿縫隙欣賞 纜車票有包 單軌電車沒有包 午餐自理', NULL, NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 5, '2026-04-08', 0, 7, '09:40', '19:00', '伊根舟屋', '船票有包，海鷗餌100日圓', NULL, NULL),
('f6492351-e28e-47c8-a33f-873b87e11539', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'f6492351-e28e-47c8-a33f-873b87e11539', 6, '2026-04-09', 0, 0, '06:00', '7:30', '起床 (作業)', '6:00起床 7:30出門', NULL, NULL),
('a60741e3-2041-412a-a5e5-15928ee9d631', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'a60741e3-2041-412a-a5e5-15928ee9d631', 6, '2026-04-09', 0, 1, '09:00', '18:00', '環球影城 (吃喝)', '9:00-10:00 好來塢美夢(先去排)/太空幻想列車/買柯南犯人娃娃 10:00-11:30 咚其剛跟馬力歐(2快通加拍照) 11:30 吃飯 12:30-13:00 水世界（來不及就先去玩太空幻想列車） 14:15~16:20 柯南密室團脫(買柯南犯人娃娃) 16:30飛天異龍or侏儸紀 17:00 太空幻想列車OR小小兵瘋狂乘車遊or水世界 18:00 哈利波特 18:30 買紀念品（18:15妖魔鬼怪搖滾樂表演秀)', 'https://maps.app.goo.gl/SXhRz36NhxqWCTYr9', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 6, '2026-04-09', 0, 7, '09:00', '18:00', '環球影城 (餐點)', 'Mario Cafe & Store™(可用手機點餐) (賣鬆餅蛋糕跟可愛杯子飲料) 奇諾比奧咖啡店(有賣正餐)(有手機點餐) 親善碼頭餐廳(有賣正餐)(有手機點餐) 史努比外景咖啡廳(有賣正餐)(有手機點餐)', NULL, NULL),
('2e720613-77cb-4b64-9aa1-52a75c52f9c8', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '2e720613-77cb-4b64-9aa1-52a75c52f9c8', 7, '2026-04-10', 0, 0, '09:00', '10:00', '起床 (作業)', '9:00起床 10:00出門', NULL, NULL),
('36d1f991-b09c-4380-b27b-c5019c8db626', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '36d1f991-b09c-4380-b27b-c5019c8db626', 7, '2026-04-10', 0, 1, '10:00', '11:00', '去日航飯店放行李(40min)', '地鐵 櫻島車站>ＪＲ夢咲線(3站)(大阪環狀線)(3站)>大阪車站 梅田>(御堂筋線)4站>心齋橋站', 'https://maps.app.goo.gl/CPNFYi7WoNngxDJL6', NULL),
('4e07d260-4220-4fdc-a0fe-b916e6703b3d', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '4e07d260-4220-4fdc-a0fe-b916e6703b3d', 7, '2026-04-10', 0, 3, '13:30', '15:00', '造幣局櫻花通道 (景點)', '西大橋>長堀鶴見綠地線(8站)>京橋（大阪）>步行1km 預約13:30-14:00，qrcode 入場 ', 'https://maps.app.goo.gl/HKWKohwKky6qxcZ59', NULL),
('2194b1ed-fb22-4bc0-b8bf-931cff2c8163', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '2194b1ed-fb22-4bc0-b8bf-931cff2c8163', 7, '2026-04-10', 0, 4, NULL, NULL, '大阪城 (景點)', '心齋橋站>長堀鶴見綠地線(6站)>大阪商務園區 步行900m 天守閣門票 kkday$241', 'https://maps.app.goo.gl/7VGgnqFo63ZbbQJK8', NULL),
('e42fdc50-b6e0-4bf8-9b33-e970987a5ff4', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'e42fdc50-b6e0-4bf8-9b33-e970987a5ff4', 7, '2026-04-10', 0, 5, NULL, NULL, '回到心齋橋逛街 (景點)', '天滿橋>谷町線(2站)>東梅田 梅田>御堂筋線(3站)>心齋橋站 固力果 https://maps.app.goo.gl/xcoX97HJj2gGwFHe8 章魚燒甲賀流 アメリカ村本店 https://maps.app.goo.gl/pj4ZaG4fQHi6tWF89 美國村', NULL, NULL),
('7093a30e-f47c-4dd3-840e-15e04c16b9eb', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '7093a30e-f47c-4dd3-840e-15e04c16b9eb', 7, '2026-04-10', 0, 6, '19:15', NULL, '吃晚餐-(焼肉力丸心齋橋店)', '訂位19:15', 'https://maps.app.goo.gl/iCPYnUroqbzFQeU99', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 7, '2026-04-10', 0, 7, '12:00', '13:00', '吃午餐(~とんかつ 豚しゃぶ 樋ぞの)', 'hizonoとんかつ 豚しゃぶ 樋ぞの  訂位12:00', 'https://maps.app.goo.gl/HrfWtLXpWWebot3Q9', NULL),
('ce134d7f-af3b-44e6-adae-2cb443bc48e4', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'ce134d7f-af3b-44e6-adae-2cb443bc48e4', 7, '2026-04-10', 0, 7, NULL, NULL, '大阪日航酒店 (住宿)', NULL, 'https://maps.app.goo.gl/CPNFYi7WoNngxDJL6', NULL),
('d299e13b-1c09-4947-885f-a40ab6b8d984', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'd299e13b-1c09-4947-885f-a40ab6b8d984', 8, '2026-04-11', 0, 0, '07:30', '9:00', '起床 (作業)', '9:00出門', NULL, NULL),
('0ce2492b-d8ef-4771-b290-c1aa049b0ae4', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '0ce2492b-d8ef-4771-b290-c1aa049b0ae4', 8, '2026-04-11', 0, 1, NULL, NULL, '早餐 (吃喝)', NULL, NULL, NULL),
('9bfde440-efc1-46ca-913f-467570bfc817', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '9bfde440-efc1-46ca-913f-467570bfc817', 8, '2026-04-11', 0, 2, NULL, NULL, '梅田逛街', '寶可夢中心 大阪大丸梅田店13f https://maps.app.goo.gl/vMmeTuP61MCaWLS38 はなだこ章魚燒 https://maps.app.goo.gl/EiDsNpE7KbtDPL4f6', 'https://maps.app.goo.gl/BkmBXtg9wDZQTsye6', NULL),
('19e8c6a7-63ca-486f-ae8c-e12e8c8f0a6a', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '19e8c6a7-63ca-486f-ae8c-e12e8c8f0a6a', 8, '2026-04-11', 0, 3, NULL, NULL, '午餐-すき焼 しゃぶしゃぶつかだ KITTE大阪', '好好吃的壽喜燒 也可以吃別的qwq', 'https://maps.app.goo.gl/SJ7kUYC6icSxGpKs6', NULL),
('c3355099-22ee-4711-baf3-301de1e285e7', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'c3355099-22ee-4711-baf3-301de1e285e7', 8, '2026-04-11', 0, 4, NULL, NULL, 'HEP FIVE、中崎町', '逛逛逛 中崎町 懷舊雜物小店 動物雑貨ONLY PLANET https://maps.app.goo.gl/FekL8M243FPjwM1y5 日本柑仔店Horiike https://maps.app.goo.gl/sZiUMsxvLvCc8wWr6 kaju_0808(飾品) 天五中崎通商店街(可搭谷町線一站地鐵過去)或走過去 https://maps.app.goo.gl/EqdFDBfJzTdTC76GA', NULL, NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 8, '2026-04-11', 0, 7, NULL, NULL, '咖啡廳neel nakazakicho', E'奶油糖霜薄可餅 備選 cafe太陽ノ塔 本店 https://maps.app.goo.gl/M1hT7THFScBAuPYJ7 OSA COFFEE https://maps.app.goo.gl/BN8rASkUKoPp2o5CA\nMARK COFFEE ROASTERS\nhttps://maps.app.goo.gl/Qfcj6Sah8GgY5qEG9', 'https://maps.app.goo.gl/XAYJXUMR5CWiMe769', NULL),
(gen_random_uuid(), 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', gen_random_uuid(), 8, '2026-04-11', 0, 7, NULL, NULL, '晚餐-すし酒場 さしす', 'すし酒場 さしす ', 'https://maps.app.goo.gl/n7bM5YK85uB7murMA', NULL),
('e5e4eff8-1c42-44b3-80df-81cdd08042e8', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'e5e4eff8-1c42-44b3-80df-81cdd08042e8', 8, '2026-04-11', 0, 7, NULL, NULL, '大阪日航酒店 (住宿)', NULL, 'https://maps.app.goo.gl/CPNFYi7WoNngxDJL6', NULL),
('fccfffa6-b280-413e-9643-7b8c40465b91', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', 'fccfffa6-b280-413e-9643-7b8c40465b91', 9, '2026-04-12', 0, 0, '06:10', '7:00', '起床 (作業)', '6:10起床 7:00出門', NULL, NULL),
('379ad8f7-1f94-4e14-838c-4ce7d1567363', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '379ad8f7-1f94-4e14-838c-4ce7d1567363', 9, '2026-04-12', 0, 1, '10:45', NULL, '航班 MM031 (移動)', '7:00 心齋橋站>御堂筋線(1站)>難波站 南海難波>ＲＡＰＩＴα 7>關西機場 8:15到機場 要到第二航廈 10:45>(MM031)>13:10', NULL, NULL),
('845dcdaa-d594-4608-a0d2-a387e4081545', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '845dcdaa-d594-4608-a0d2-a387e4081545', 9, '2026-04-12', 0, 2, NULL, NULL, '往勝尾寺', '大國町站>御堂筋線(10站)北大阪急行線(5站)>箕面萱野站 巴士：「箕面萱野站 阪急巴士8號乘車處」出發 箕面萱野站 → 勝尾寺', 'https://maps.app.goo.gl/kPs23DVxUTNUEAtW7', NULL),
('6f3911a0-f975-4d78-aa20-662dcf6937c7', 'a3f8c2d1-7e4b-4f9a-b561-8d2e0c7a3f15', '6f3911a0-f975-4d78-aa20-662dcf6937c7', 9, '2026-04-12', 0, 3, NULL, NULL, '大阪日航酒店 (住宿)', NULL, 'https://maps.app.goo.gl/CPNFYi7WoNngxDJL6', NULL),
('a0621721-fb7b-417c-916a-c479a1a995eb', '2e18e026-036a-4410-be83-06d7dc2864ab', 'a0621721-fb7b-417c-916a-c479a1a995eb', 1, '2026-08-12', 0, 1, '14:55', '16:00', '成田機場到東京車站', E'第一航廈 LCB(綠色)巴士到東京車站\n\n成田機場到東京車站，超值省力的「Airport Bus TYO-NRT」 | shushu自由研究所 https://share.google/AEIKt9eAKDtpM0aqT', NULL, NULL),
('a320e488-3911-495b-810e-acbcc72592c6', '2e18e026-036a-4410-be83-06d7dc2864ab', 'a320e488-3911-495b-810e-acbcc72592c6', 1, '2026-08-12', 0, 2, '16:55', '17:25', 'KOKO HOTEL 新宿四谷放行李', 'https://maps.app.goo.gl/miNT4pvBD9fMpey37', NULL, NULL),
('c3d15504-e248-48ab-9b40-251f99c3f454', '2e18e026-036a-4410-be83-06d7dc2864ab', 'c3d15504-e248-48ab-9b40-251f99c3f454', 1, '2026-08-12', 0, 3, '17:25', '18:10', 'BEAMS JAPAN', '四谷三丁目>丸之內線2站>新宿三丁目', 'https://maps.app.goo.gl/xegfuYu4PZhhm2rg6', NULL),
('f0f93be9-55c8-4083-af3e-6ababa182131', '2e18e026-036a-4410-be83-06d7dc2864ab', 'f0f93be9-55c8-4083-af3e-6ababa182131', 1, '2026-08-12', 0, 4, '18:10', '18:35', '去新宿車站買東京廣域周遊券', E'東京廣域周遊券¥16000\n綠色JR買票\n順便劃位明日新幹線車票', NULL, NULL),
(gen_random_uuid(), '2e18e026-036a-4410-be83-06d7dc2864ab', gen_random_uuid(), 1, '2026-08-12', 0, 5, '18:35', '19:25', 'test', NULL, NULL, NULL),
('e0eaee8b-9f83-45ca-b4ef-dddb93f244c3', '2e18e026-036a-4410-be83-06d7dc2864ab', 'e0eaee8b-9f83-45ca-b4ef-dddb93f244c3', 1, '2026-08-12', 0, 6, '19:25', '21:10', 'LUMINE EST Shinjuku', NULL, 'https://maps.app.goo.gl/daUryUY3avhe8aMp8', NULL),
('ed058e2b-ae5b-4b4c-a091-55370276d5e8', '2e18e026-036a-4410-be83-06d7dc2864ab', 'ed058e2b-ae5b-4b4c-a091-55370276d5e8', 1, '2026-08-12', 0, 7, '21:10', NULL, 'KOKO HOTEL 新宿四谷', NULL, 'https://maps.app.goo.gl/miNT4pvBD9fMpey37', NULL),
('7538caa4-cbed-4ed1-a921-9981a2077684', '2e18e026-036a-4410-be83-06d7dc2864ab', '7538caa4-cbed-4ed1-a921-9981a2077684', 2, '2026-08-13', 0, 1, '8:00', '9:30', '起床', NULL, NULL, NULL),
('e902b29a-4fa7-42b7-8a4e-567459b3c574', '2e18e026-036a-4410-be83-06d7dc2864ab', 'e902b29a-4fa7-42b7-8a4e-567459b3c574', 2, '2026-08-13', 0, 2, '09:30', '10:30', '吃早餐', NULL, NULL, NULL),
('16682619-bd5c-4e30-b055-040715e77fe4', '2e18e026-036a-4410-be83-06d7dc2864ab', '16682619-bd5c-4e30-b055-040715e77fe4', 2, '2026-08-13', 0, 3, '11:00', '12:20', '到飯店放行李（高崎華盛頓廣場飯店 高崎ワシントンホテルプラザ）', E'9:13四谷三丁目>丸之內線(6站)>東京車站\n東京車站9：44>北陸新幹線(長野)>高崎\n飯店放行李10:40-11:00', 'https://maps.app.goo.gl/nHhqWbo7HExN2e4V8', NULL),
('7849051a-4cb3-415e-b021-67fafe3bc5ac', '2e18e026-036a-4410-be83-06d7dc2864ab', '7849051a-4cb3-415e-b021-67fafe3bc5ac', 2, '2026-08-13', 0, 4, '11:20', '11:35', '新幹線到輕井澤', E'高崎11:21>輕井澤11:36\n(半小時一班)', NULL, NULL),
('1b57fa16-58ac-4dfd-ac5d-f8256e43d71a', '2e18e026-036a-4410-be83-06d7dc2864ab', '1b57fa16-58ac-4dfd-ac5d-f8256e43d71a', 2, '2026-08-13', 0, 5, '13:20', '18:00', '輕井澤outlet ', E'\n', 'https://maps.app.goo.gl/iqoryUT5G5RtbXxj7', NULL),
('f436450c-4590-458b-a27a-7063e91ae208', '2e18e026-036a-4410-be83-06d7dc2864ab', 'f436450c-4590-458b-a27a-7063e91ae208', 2, '2026-08-13', 0, 6, '21:00', '22:00', 'Fukumimi Hanare 串焼BISTRO福みみ 新宿店 はなれ', NULL, 'https://maps.app.goo.gl/vSXibWtwJRCRgydK7?g_st=ac', NULL),
('76dbc99c-8d0c-4870-a9a5-87dbe0fba3d2', '2e18e026-036a-4410-be83-06d7dc2864ab', 'f436450c-4590-458b-a27a-7063e91ae208', 2, '2026-08-13', 1, 6, '21:00', '22:00', '牛たん 荒 新宿店', NULL, 'https://maps.app.goo.gl/qTJMagvU8wnfMfS69', NULL),
('ce304301-a491-406e-a8f6-abf2e7adfb4c', '2e18e026-036a-4410-be83-06d7dc2864ab', 'f436450c-4590-458b-a27a-7063e91ae208', 2, '2026-08-13', 2, 6, '21:00', '22:00', '備案3test', NULL, NULL, NULL),
(gen_random_uuid(), '2e18e026-036a-4410-be83-06d7dc2864ab', gen_random_uuid(), 2, '2026-08-13', 0, 7, NULL, NULL, '新幹線到輕井澤', E'高崎11:21>輕井澤11:36\n(半小時一班)', NULL, NULL),
('92a37b2c-1d83-4542-9dc0-ae3364f7cd8d', '2e18e026-036a-4410-be83-06d7dc2864ab', '92a37b2c-1d83-4542-9dc0-ae3364f7cd8d', 3, '2026-08-14', 0, 1, '10:15', '10:30', '白貓自行車', NULL, 'https://maps.app.goo.gl/YNV8z7MKpNcVSptQ6', NULL),
('55d7bb29-0052-4720-b965-ca334ff7a4db', '2e18e026-036a-4410-be83-06d7dc2864ab', '55d7bb29-0052-4720-b965-ca334ff7a4db', 3, '2026-08-14', 0, 2, '11:00', '14:00', '旧軽井沢銀座商店街', NULL, 'https://maps.app.goo.gl/4cEPTTpfEPESmyhC6', NULL),
('438532b8-4a2a-4613-a5f3-05275f64b175', '2e18e026-036a-4410-be83-06d7dc2864ab', '438532b8-4a2a-4613-a5f3-05275f64b175', 3, '2026-08-14', 0, 3, '11:30', '12:30', 'Atelier de Fromage Pizzeria (午餐）', NULL, 'https://maps.app.goo.gl/8cdvHD8DrWMpDfPeA?g_st=ac', NULL),
('35174682-ce7b-4f09-912e-404eb804d8cb', '2e18e026-036a-4410-be83-06d7dc2864ab', '35174682-ce7b-4f09-912e-404eb804d8cb', 3, '2026-08-14', 0, 4, '18:10', '18:15', '宇都宮駅', E'大宮轉車\n套票不可坐山形新幹線\n要坐東北新幹線', 'https://maps.app.goo.gl/vxDRa58sguZraAjVA', NULL),
('b69779b4-4f32-4771-8df3-46ffd946e553', '2e18e026-036a-4410-be83-06d7dc2864ab', 'b69779b4-4f32-4771-8df3-46ffd946e553', 3, '2026-08-14', 0, 5, '18:30', '18:30', 'Richmond Hotel宇都宮站前', NULL, 'https://maps.app.goo.gl/xNvNGy2citfNkjxs8', NULL),
('847d92ee-4e73-4f3a-8734-5b45066c7b7d', '2e18e026-036a-4410-be83-06d7dc2864ab', '847d92ee-4e73-4f3a-8734-5b45066c7b7d', 3, '2026-08-14', 0, 7, NULL, NULL, '軽井沢駅', NULL, 'https://maps.app.goo.gl/282Xri89iTPLS5cRA', NULL),
('510cc385-a8c4-408f-b8f8-e41c03c80408', '2e18e026-036a-4410-be83-06d7dc2864ab', '510cc385-a8c4-408f-b8f8-e41c03c80408', 3, '2026-08-14', 0, 8, NULL, NULL, '高崎站', '9:55的車', 'https://maps.app.goo.gl/hJ45pSGvyVL5gQoS6', NULL),
('206ade55-474c-4fc4-b915-c475fd831e75', '2e18e026-036a-4410-be83-06d7dc2864ab', '206ade55-474c-4fc4-b915-c475fd831e75', 3, '2026-08-14', 0, 9, NULL, NULL, '雲場池', NULL, 'https://maps.app.goo.gl/13kh3BBaHJvBtPq97', NULL),
('f4c45dfc-6c4e-4eb5-b18d-93ca1229d003', '2e18e026-036a-4410-be83-06d7dc2864ab', gen_random_uuid(), 3, '2026-08-14', 0, 10, NULL, NULL, 'LUMINE EST Shinjuku', NULL, 'https://maps.app.goo.gl/daUryUY3avhe8aMp8', NULL),
('f1b50a96-4e5e-44b4-bff5-150c2533ade5', '2e18e026-036a-4410-be83-06d7dc2864ab', 'f1b50a96-4e5e-44b4-bff5-150c2533ade5', 4, '2026-08-15', 0, 0, '8:30', '8:45', '宇都宮駅', E'8:46 日光線\n9:28到日光\n9:42 公車前往瀑布(中禪寺溫泉站)\n10:30抵達', 'https://maps.app.goo.gl/vxDRa58sguZraAjVA', NULL),
('272f27a5-dd97-4ecc-a4ca-bebc6b1fb20c', '2e18e026-036a-4410-be83-06d7dc2864ab', '272f27a5-dd97-4ecc-a4ca-bebc6b1fb20c', 4, '2026-08-15', 0, 1, '11:00', '11:30', '華嚴瀑布', NULL, 'https://maps.app.goo.gl/ik9UQ9ZNgxsFV98d7', NULL),
('8fe72274-f1c8-4647-b3f8-64af70a298fc', '2e18e026-036a-4410-be83-06d7dc2864ab', '8fe72274-f1c8-4647-b3f8-64af70a298fc', 4, '2026-08-15', 0, 2, '11:30', '13:30', '中禪寺湖', E'13:32有回程公車\n從中禪寺溫泉站', 'https://maps.app.goo.gl/GPLJwwU3Rj3SjW4M6', NULL),
('6f0e5ca1-94dd-4bc8-9a34-1ff17e0b0c90', '2e18e026-036a-4410-be83-06d7dc2864ab', '6f0e5ca1-94dd-4bc8-9a34-1ff17e0b0c90', 4, '2026-08-15', 0, 3, '14:15', '16:00', '日光東照宮', '1500日幣，前一天可以先到kkday買票不用排隊', 'https://maps.app.goo.gl/P9gYNwqFEdaCFfu48', NULL),
('a7b5d536-5328-420b-813a-b3b0f4895ead', '2e18e026-036a-4410-be83-06d7dc2864ab', 'a7b5d536-5328-420b-813a-b3b0f4895ead', 4, '2026-08-15', 0, 4, '16:00', '16:15', 'BEAMS JAPAN 日光', NULL, 'https://maps.app.goo.gl/JNpxXmwfgFGqUHEF8', NULL),
('3734bac3-e718-4026-bf59-d4df104bc28e', '2e18e026-036a-4410-be83-06d7dc2864ab', '3734bac3-e718-4026-bf59-d4df104bc28e', 4, '2026-08-15', 0, 5, '20:00', '20:00', 'HOTEL TOKYO TRIP', NULL, 'https://maps.app.goo.gl/5Q54GjoAsSDNkc638', NULL),
('bcf6912d-b432-40aa-afa6-a8f4c56a82c2', '2e18e026-036a-4410-be83-06d7dc2864ab', 'bcf6912d-b432-40aa-afa6-a8f4c56a82c2', 4, '2026-08-15', 0, 6, NULL, NULL, '宇都宮駅', '拿行李', NULL, NULL),
('0e05bc17-fdc5-4709-8a11-cfe7118fcb8c', '2e18e026-036a-4410-be83-06d7dc2864ab', '0e05bc17-fdc5-4709-8a11-cfe7118fcb8c', 4, '2026-08-15', 0, 7, NULL, NULL, 'HOTEL TOKYO TRIP', NULL, 'https://maps.app.goo.gl/2STuNd9HBws4npGy8', NULL),
('67382cef-d941-451e-9a85-10e9a9287db3', '2e18e026-036a-4410-be83-06d7dc2864ab', '67382cef-d941-451e-9a85-10e9a9287db3', 4, '2026-08-15', 0, 8, NULL, NULL, '和牛一頭焼肉 房家 西日暮里本店', '開到23:15', 'https://maps.app.goo.gl/iyw5rvnkYBabVapa6', NULL),
('4b6fd6c3-6160-490a-9c96-6da3861ced82', '2e18e026-036a-4410-be83-06d7dc2864ab', '4b6fd6c3-6160-490a-9c96-6da3861ced82', 5, '2026-08-16', 0, 0, NULL, NULL, '（待新增）', NULL, NULL, NULL)
ON CONFLICT ("Id") DO UPDATE SET
  "GroupId" = EXCLUDED."GroupId",
  "Day" = EXCLUDED."Day",
  "Date" = EXCLUDED."Date",
  "AltOrder" = EXCLUDED."AltOrder",
  "SortOrder" = EXCLUDED."SortOrder",
  "AttractionName" = EXCLUDED."AttractionName",
  "StartTime" = EXCLUDED."StartTime",
  "EndTime" = EXCLUDED."EndTime",
  "Remark" = EXCLUDED."Remark",
  "GoogleMapLink" = EXCLUDED."GoogleMapLink",
  "ImageUrl" = EXCLUDED."ImageUrl";
