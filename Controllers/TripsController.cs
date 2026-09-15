using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;
using TravelApp.Api.Services;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 旅程管理 API 控制器，提供旅程的建立、查詢、刪除、共編者管理與天數卡片重排等功能
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class TripsController(AppDbContext db, TripAuthService auth) : ControllerBase
{
    /// <summary>
    /// 取得當前登入者所擁有或受邀共編的所有旅程清單
    /// </summary>
    /// <returns>旅程清單</returns>
    // GET api/trips
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var currentUserId = TripAuthService.GetUserId(User);
        var currentEmail = TripAuthService.GetUserEmail(User)?.ToLowerInvariant();

        // 查詢條件：當前使用者為擁有者、受邀共編者，或是未設定擁有者的公開示範旅程
        var query = db.Trips
            .Include(t => t.Collaborators)
            .AsNoTracking();

        if (!string.IsNullOrEmpty(currentUserId) || !string.IsNullOrEmpty(currentEmail))
        {
            query = query.Where(t =>
                string.IsNullOrEmpty(t.UserId) ||
                t.UserId == currentUserId ||
                (!string.IsNullOrEmpty(currentEmail) && t.Collaborators.Any(c => c.UserEmail == currentEmail)));
        }

        var trips = await query
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.TripId,
                t.ReadOnlyId,
                t.Name,
                t.StartDate,
                t.EndDate,
                t.CoverUrl,
                IsOwner = string.IsNullOrEmpty(t.UserId) || t.UserId == currentUserId
            })
            .ToListAsync();

        return Ok(trips);
    }

    /// <summary>
    /// 取得特定旅程的詳細內容與每日行程分組 (支援可編輯 UUID 或唯讀 UUID 查詢)
    /// </summary>
    /// <param name="id">旅程的 UUID (tripId 或 readOnlyId)</param>
    /// <returns>旅程詳細資料</returns>
    // GET api/trips/{id}
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(Guid id)
    {
        // 1. 先找 tripId
        var trip = await db.Trips
            .Include(t => t.TripInfo)
            .Include(t => t.Schedules)
            .Include(t => t.Collaborators)
            .FirstOrDefaultAsync(t => t.TripId == id);

        bool isReadOnly = false;

        // 2. 找不到再找 readOnlyId (唯讀訪客分享模式)
        if (trip == null)
        {
            trip = await db.Trips
                .Include(t => t.TripInfo)
                .Include(t => t.Schedules)
                .Include(t => t.Collaborators)
                .FirstOrDefaultAsync(t => t.ReadOnlyId == id);

            if (trip == null)
                return NotFound(new { error = $"找不到 tripId: {id}" });

            isReadOnly = true;
        }
        else
        {
            // 若為 tripId 查詢，檢查是否具備編輯權限
            var canEdit = await auth.CanEditAsync(trip.TripId, User);
            if (!canEdit)
            {
                // 若無編輯權限，自動轉為唯讀模式瀏覽
                isReadOnly = true;
            }
        }

        // 3. 依 Day 分組並保全空天數 (Day 1 ~ Day N)
        int maxCardDay = trip.Schedules.Any() ? trip.Schedules.Max(s => s.Day) : 0;
        int dateDays = 0;
        DateTime? startDate = null;

        if (!string.IsNullOrEmpty(trip.StartDate) && !string.IsNullOrEmpty(trip.EndDate)
            && DateTime.TryParse(trip.StartDate, out var start)
            && DateTime.TryParse(trip.EndDate, out var end)
            && end >= start)
        {
            startDate = start;
            dateDays = (int)(end - start).TotalDays + 1;
        }

        int totalDays = Math.Max(dateDays, maxCardDay);

        var journeys = new List<object>();
        for (int i = 1; i <= totalDays; i++)
        {
            var dayNum = i;
            var dayDate = startDate.HasValue ? startDate.Value.AddDays(dayNum - 1).ToString("yyyy-MM-dd") : null;
            var daySchedules = trip.Schedules
                .Where(s => s.Day == dayNum)
                .OrderBy(s => s.SortOrder)
                .Select(s => new
                {
                    s.Id,
                    s.GroupId,
                    s.TripId,
                    s.Day,
                    Date = s.Date ?? dayDate,
                    s.AltOrder,
                    s.SortOrder,
                    s.AttractionName,
                    s.StartTime,
                    s.EndTime,
                    s.Remark,
                    s.GoogleMapLink,
                    s.ImageUrl
                })
                .ToList();

            journeys.Add(new
            {
                Day = dayNum,
                Date = daySchedules.FirstOrDefault()?.Date ?? dayDate,
                Schedule = daySchedules
            });
        }

        return Ok(new
        {
            trip.TripId,
            trip.ReadOnlyId,
            IsReadOnly = isReadOnly,
            trip.Name,
            trip.StartDate,
            trip.EndDate,
            trip.CoverUrl,
            TripInfo = trip.TripInfo,
            Journeys = journeys
        });
    }

    /// <summary>
    /// 建立一趟新旅程並自動綁定當前登入者
    /// </summary>
    /// <param name="req">建立旅程請求參數</param>
    /// <returns>新增成功的狀態與 UUIDs</returns>
    // POST api/trips
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTripRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest(new { status = "error", message = "行程名稱為必填" });

        var currentUserId = TripAuthService.GetUserId(User);

        var trip = new Trip
        {
            TripId = Guid.NewGuid(),
            ReadOnlyId = Guid.NewGuid(),
            Name = req.Name.Trim(),
            StartDate = req.StartDate,
            EndDate = req.EndDate,
            CoverUrl = req.CoverUrl,
            UserId = currentUserId,
            CreatedAt = DateTime.UtcNow
        };

        db.Trips.Add(trip);
        await db.SaveChangesAsync();

        return Ok(new
        {
            status = "success",
            message = "建立旅遊計畫成功",
            tripId = trip.TripId,
            readOnlyId = trip.ReadOnlyId,
            data = new
            {
                tripId = trip.TripId,
                readOnlyId = trip.ReadOnlyId,
                name = trip.Name,
                startDate = trip.StartDate,
                endDate = trip.EndDate,
                coverUrl = trip.CoverUrl
            }
        });
    }

    /// <summary>
    /// 刪除一趟旅程 (嚴格僅限擁有者 Owner 才能刪除)
    /// </summary>
    /// <param name="id">旅程 ID</param>
    /// <returns>成功狀態訊息</returns>
    // DELETE api/trips/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var trip = await db.Trips.FindAsync(id);
        if (trip == null) return NotFound(new { status = "error", message = "找不到此旅程" });

        if (!await auth.IsOwnerAsync(id, User))
            return StatusCode(403, new { status = "error", message = "無刪除權限或非此旅程擁有者" });

        db.Trips.Remove(trip);
        await db.SaveChangesAsync();
        return Ok(new { status = "success", message = "旅程已成功刪除" });
    }

    // ── 共編者管理 API (Collaborators) ───────────────────────────

    /// <summary>
    /// 取得特定旅程的擁有者與共編者名單
    /// </summary>
    // GET api/trips/{tripId}/collaborators
    [HttpGet("{tripId:guid}/collaborators")]
    public async Task<IActionResult> GetCollaborators(Guid tripId)
    {
        if (!await auth.CanEditAsync(tripId, User))
            return StatusCode(403, new { status = "error", message = "無權限查看此旅程的共編者名單" });

        return Ok(await BuildCollaboratorsResult(tripId));
    }

    /// <summary>
    /// 新增旅程共編者 (輸入 Google Email，僅限 Owner)
    /// </summary>
    // POST api/trips/{tripId}/collaborators
    [HttpPost("{tripId:guid}/collaborators")]
    public async Task<IActionResult> AddCollaborator(Guid tripId, [FromBody] CollaboratorRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email))
            return BadRequest(new { status = "error", message = "請輸入有效的 Google Email" });

        if (!await auth.IsOwnerAsync(tripId, User))
            return StatusCode(403, new { status = "error", message = "只有旅程擁有者可以新增共編者" });

        var trip = await db.Trips.FindAsync(tripId);
        if (trip == null) return NotFound(new { status = "error", message = "找不到旅程" });

        var targetEmail = req.Email.Trim().ToLowerInvariant();

        // 檢查是否為擁有者自己
        if (!string.IsNullOrEmpty(trip.UserId))
        {
            var owner = await db.Users.FindAsync(trip.UserId);
            if (owner != null && owner.Email.Equals(targetEmail, StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new { status = "error", message = "建立者本身已具備完整編輯權限，無需加入共編" });
            }
        }

        // 檢查是否已存在名單中
        var exists = await db.TripCollaborators
            .AnyAsync(c => c.TripId == tripId && c.UserEmail == targetEmail);
        if (!exists)
        {
            db.TripCollaborators.Add(new TripCollaborator
            {
                TripId = tripId,
                UserEmail = targetEmail,
                Role = "editor",
                AddedAt = DateTime.UtcNow
            });
            await db.SaveChangesAsync();
        }

        return Ok(await BuildCollaboratorsResult(tripId));
    }

    /// <summary>
    /// 移除旅程共編者 (僅限 Owner)
    /// </summary>
    // DELETE api/trips/{tripId}/collaborators/{email}
    [HttpDelete("{tripId:guid}/collaborators/{email}")]
    [HttpPost("{tripId:guid}/collaborators/remove")]
    public async Task<IActionResult> RemoveCollaborator(Guid tripId, string? email, [FromBody] CollaboratorRequest? bodyReq)
    {
        var targetEmail = email ?? bodyReq?.Email;
        if (string.IsNullOrWhiteSpace(targetEmail))
            return BadRequest(new { status = "error", message = "缺少 email 參數" });

        if (!await auth.IsOwnerAsync(tripId, User))
            return StatusCode(403, new { status = "error", message = "只有旅程擁有者可以移除共編者" });

        targetEmail = targetEmail.Trim().ToLowerInvariant();
        var record = await db.TripCollaborators
            .FirstOrDefaultAsync(c => c.TripId == tripId && c.UserEmail == targetEmail);

        if (record != null)
        {
            db.TripCollaborators.Remove(record);
            await db.SaveChangesAsync();
        }

        return Ok(await BuildCollaboratorsResult(tripId));
    }

    /// <summary>
    /// 每日行程卡片重新排序
    /// </summary>
    // PUT api/trips/{tripId}/days/{day}/reorder
    [HttpPut("{tripId:guid}/days/{day:int}/reorder")]
    public async Task<IActionResult> ReorderDaySchedules(Guid tripId, int day, [FromBody] DayReorderRequest req)
    {
        if (!await auth.CanEditAsync(tripId, User))
            return StatusCode(403, new { status = "error", message = "無編輯權限或非旅程擁有者" });

        var schedules = await db.Schedules
            .Where(s => s.TripId == tripId && s.Day == day)
            .ToListAsync();

        var orderedIds = req.OrderedIds ?? [];
        for (int i = 0; i < orderedIds.Count; i++)
        {
            var targetId = orderedIds[i];
            // 同時更新卡片 ID 或同一 GroupId
            foreach (var s in schedules.Where(s => s.Id == targetId || s.GroupId == targetId))
            {
                s.SortOrder = i;
            }
        }

        await db.SaveChangesAsync();
        return Ok(new { status = "success", message = "排序更新成功" });
    }

    /// <summary>
    /// 組合共編者查詢結果資料
    /// </summary>
    private async Task<object> BuildCollaboratorsResult(Guid tripId)
    {
        var trip = await db.Trips.FindAsync(tripId);
        var tripName = trip?.Name ?? string.Empty;

        // 擁有者資訊
        object ownerInfo;
        if (!string.IsNullOrEmpty(trip?.UserId))
        {
            var user = await db.Users.FindAsync(trip.UserId);
            ownerInfo = new
            {
                userId = trip.UserId,
                email = user?.Email ?? "",
                name = user?.Name ?? "旅程建立者",
                picture = user?.Picture ?? "",
                isOwner = true
            };
        }
        else
        {
            ownerInfo = new
            {
                userId = "",
                email = "",
                name = "示範旅程",
                picture = "",
                isOwner = true
            };
        }

        // 共編者名單 (串接 User 資訊以顯示名稱與照片)
        var collabs = await db.TripCollaborators
            .Where(c => c.TripId == tripId)
            .ToListAsync();

        var emails = collabs.Select(c => c.UserEmail).ToList();
        var matchedUsers = await db.Users
            .Where(u => emails.Contains(u.Email))
            .ToListAsync();

        var list = collabs.Select(c =>
        {
            var u = matchedUsers.FirstOrDefault(mu => mu.Email.Equals(c.UserEmail, StringComparison.OrdinalIgnoreCase));
            return new
            {
                tripId = c.TripId,
                userEmail = c.UserEmail,
                userId = u?.UserId ?? "",
                name = u?.Name ?? c.UserEmail,
                picture = u?.Picture ?? "",
                role = c.Role
            };
        }).ToList();

        return new
        {
            status = "success",
            tripName,
            owner = ownerInfo,
            collaborators = list
        };
    }
}

public record CreateTripRequest(string Name, string? StartDate, string? EndDate, string? CoverUrl);
public record CollaboratorRequest(string? Email);
public record DayReorderRequest(Guid? TripId, int? Day, List<Guid>? OrderedIds);
