# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-16

### Added
- **ASP.NET Core 10 RESTful API 基礎架構**：
  - 基於 .NET 10 與 Entity Framework Core (Npgsql) 建立高效能旅行計畫管理後端。
  - 支援 OpenAPI / Swagger 文件生成與端點描述（`/openapi/v1.json`）。
  - 配置自適應跨來源資源共用 (CORS) 政策，允許本地開發環境（`localhost:*`）與生產環境（`*.github.io`）跨網域呼叫。
  - 提供雲端保持活躍健康檢查端點（`GET /health`），供 UptimeRobot 等監控服務定時發送 Keep-Alive 請求避免 Render 容器休眠。

- **Google OAuth 2.0 雙層身分驗證與 JWT 權杖系統**：
  - **Token 驗證 (`POST /api/auth/google`)**：透過 Google 官方 `tokeninfo` API 驗證前端 Google Identity Services (GIS) 回傳的 ID Token，校驗簽章真偽與 ClientId Audience。
  - **雙 Token 機制 (Dual-Token Architecture)**：
    - 發行 15 分鐘短效期之 JWT Access Token（以 HMAC-SHA256 簽署）。
    - 發行 30 天長效期之 Session Refresh Token，儲存於資料庫 `UserSessions` 表，支援安全登出與權杖撤銷（Revocation）。
  - **無感自動刷新 (`POST /api/auth/refresh`)**：支援前端於過期前以 Refresh Token 換取全新 Access Token，提供不中斷的使用者體驗。
  - **主動登出 (`POST /api/auth/logout`)**：將資料庫中的 Session 標記為 `isRevoked = true`，徹底阻斷過期連線。

- **多使用者資料隔離與旅程協作系統 (Multi-Tenancy & Collaboration)**：
  - 於 `Trips`、`PackingItems` 資料表全面導入 `UserId` 隔離機制，確保使用者僅能存取與管理自身所屬資源。
  - **旅程共編者體系 (`TripCollaborators`)**：
    - 支援旅程擁有者（Owner）透過 Email 邀請共編者（Editor）。
    - 實作 `TripAuthService` 權限守門員，統一校驗當前操作者是否具備檢視或編輯特定旅程之權限。
    - 旅程刪除與共編名單異動嚴格限定 Owner；行程卡片與航班資訊開放 Owner 及 Collaborator 共同編輯。

- **行程明細與彈性備案管理系統 (`Schedules`)**：
  - 完整支援行程卡片新增（`POST /api/schedules`）、更新（`PUT /api/schedules/{id}`）、刪除（`DELETE /api/schedules/{id}`）。
  - **行程拖曳排序 (`PUT /api/trips/{tripId}/days/{day}/reorder`)**：支援單日內行程卡片之批次重排與 `SortOrder` 更新。
  - **同群組備案換位與轉正 (`PUT /api/groups/{groupId}/reorder-backups`)**：支援同一個 `GroupId` 內多個備案方案的順序調整，並將排在首位者（`altOrder = 0`）轉正為主要行程。

- **Neon 雲端 PostgreSQL 資料庫整合與等冪性種子資料腳本 (`seed.sql`)**：
  - 全面遷移至線上 Neon Serverless PostgreSQL 資料庫。
  - 撰寫具備完整等冪性 (Idempotent) 的 DDL 與種子資料腳本，包含 `CREATE TABLE IF NOT EXISTS`、`ALTER TABLE ... ADD COLUMN IF NOT EXISTS` 以及 `INSERT ... ON CONFLICT DO UPDATE`。
  - 包含 8 張實體資料表結構：`Users`, `UserSessions`, `Trips`, `TripInfos`, `Schedules`, `PackingItems`, `TripCollaborators`, `UploadedImages`。

- **二進位圖片雲端持久化儲存 (`UploadedImages`)**：
  - 將使用者上傳之航班憑證與行程截圖以 `BYTEA` 格式儲存於 PostgreSQL，徹底解決 Render 等免費雲端容器休眠重啟時本地檔案遺失問題。
  - 提供靜態串流讀取端點（`GET /api/images/{id}`）。

### Changed
- **資料庫啟動初始化機制最佳化 (`Program.cs`)**：
  - 移除原先依賴 `!db.Trips.Any()` 判斷才執行種子腳本的限制，改為每次伺服器啟動時自動套用 `seed.sql`，確保資料庫結構與欄位能無縫隨程式碼演進更新。
- **行程新增 DTO 容錯彈性提升 (`SchedulesController.cs`)**：
  - 將 `AddScheduleRequest` 的 `GroupId` 改為寬鬆字串並以 `Guid.TryParse` 容錯解析；當前端傳入暫時字串或 `null` 時，後端自動生成全新 GUID，防止型別反序列化崩潰。
  - 新增卡片時若未提供 `sortOrder`，自動計算當天現有最大排序序號累加（`max + 1`），避免新卡片排序重疊於 0。

### Fixed
- **修正本地既有資料庫缺失 `Users` 資料表引發之 500 錯誤**：
  - 修復因 `EnsureCreated()` 未執行新表建置導致 Google 登入查詢 `db.Users` 噴出 `relation "Users" does not exist` 的問題。
- **修正本地連線字串未對齊線上 Neon 的設定問題**：
  - 更新 `appsettings.Development.json` 中的 `DefaultConnection` 直連線上 Neon PostgreSQL，完成本地開發環境與線上資料庫之對齊。
