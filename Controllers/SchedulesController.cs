using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;
using TravelApp.Api.Services;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 行程明細管理 API 控制器，提供行程卡片的新增、編輯、刪除與備案排序轉正等功能
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class SchedulesController(AppDbContext db, TripAuthService auth) : ControllerBase
{
    /// <summary>
    /// 新增一筆行程卡片項目 (或是為既有行程新增備案)
    /// </summary>
    /// <param name="req">行程新增請求參數</param>
    /// <returns>新增成功的 ID 與完整物件</returns>
    // POST api/schedules
    [HttpPost]
    public async Task<IActionResult> Add([FromBody] AddScheduleRequest req)
    {
        if (!await db.Trips.AnyAsync(t => t.TripId == req.TripId))
            return NotFound(new { status = "error", message = "找不到旅程" });

        if (!await auth.CanEditAsync(req.TripId, User))
            return StatusCode(403, new { status = "error", message = "無編輯權限或非此旅程擁有者/共編者" });

        var scheduleId = Guid.NewGuid();
        var groupId = req.GroupId ?? scheduleId; // 若未傳 groupId 則以自身 ID 作為群組起始 ID

        var schedule = new Schedule
        {
            Id = scheduleId,
            TripId = req.TripId,
            GroupId = groupId,
            Day = req.Day,
            Date = req.Date,
            AttractionName = req.AttractionName,
            StartTime = req.StartTime,
            EndTime = req.EndTime,
            Remark = req.Remark,
            GoogleMapLink = req.GoogleMapLink,
            ImageUrl = req.ImageUrl,
            SortOrder = req.SortOrder,
            AltOrder = req.AltOrder
        };

        db.Schedules.Add(schedule);
        await db.SaveChangesAsync();

        return Ok(new
        {
            status = "success",
            id = schedule.Id,
            data = schedule
        });
    }

    /// <summary>
    /// 更新特定行程明細內容 (景點名稱、時間、備註、地圖等)
    /// </summary>
    /// <param name="id">行程 ID</param>
    /// <param name="req">更新參數</param>
    /// <returns>成功狀態</returns>
    // PUT api/schedules/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateScheduleRequest req)
    {
        var schedule = await db.Schedules.FindAsync(id);
        if (schedule == null) return NotFound(new { status = "error", message = "找不到行程項目" });

        if (!await auth.CanEditAsync(schedule.TripId, User))
            return StatusCode(403, new { status = "error", message = "無編輯權限或非此旅程擁有者/共編者" });

        schedule.AttractionName = req.AttractionName ?? schedule.AttractionName;
        schedule.StartTime = req.StartTime ?? schedule.StartTime;
        schedule.EndTime = req.EndTime ?? schedule.EndTime;
        schedule.Remark = req.Remark ?? schedule.Remark;
        schedule.GoogleMapLink = req.GoogleMapLink ?? schedule.GoogleMapLink;
        schedule.ImageUrl = req.ImageUrl ?? schedule.ImageUrl;
        if (req.Date is not null) schedule.Date = req.Date;

        await db.SaveChangesAsync();
        return Ok(new { status = "success", message = "行程更新成功" });
    }

    /// <summary>
    /// 刪除特定行程項目
    /// </summary>
    /// <param name="id">行程 ID</param>
    /// <returns>成功狀態</returns>
    // DELETE api/schedules/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var schedule = await db.Schedules.FindAsync(id);
        if (schedule == null) return NotFound(new { status = "error", message = "找不到行程項目" });

        if (!await auth.CanEditAsync(schedule.TripId, User))
            return StatusCode(403, new { status = "error", message = "無編輯權限或非此旅程擁有者/共編者" });

        db.Schedules.Remove(schedule);
        await db.SaveChangesAsync();
        return Ok(new { status = "success", message = "行程已成功刪除" });
    }

    /// <summary>
    /// 改變同一個行程群組內的備案順序與轉正主要行程
    /// </summary>
    /// <param name="groupId">群組 ID</param>
    /// <param name="req">包含 orderedIds 的重排請求物件</param>
    /// <returns>成功狀態</returns>
    // PUT api/groups/{groupId}/reorder-backups
    [HttpPut("/api/groups/{groupId:guid}/reorder-backups")]
    public async Task<IActionResult> ReorderGroupBackups(Guid groupId, [FromBody] ReorderBackupsRequest req)
    {
        var schedules = await db.Schedules
            .Where(s => s.GroupId == groupId)
            .ToListAsync();

        if (schedules.Count == 0)
        {
            return NotFound(new { status = "error", message = $"找不到群組: {groupId}" });
        }

        var tripId = schedules.First().TripId;
        if (!await auth.CanEditAsync(tripId, User))
            return StatusCode(403, new { status = "error", message = "無編輯權限或非此旅程擁有者/共編者" });

        var orderedIds = req.OrderedIds ?? [];
        for (int i = 0; i < orderedIds.Count; i++)
        {
            var targetId = orderedIds[i];
            var s = schedules.FirstOrDefault(x => x.Id == targetId);
            if (s != null)
            {
                s.AltOrder = i; // 第一個轉正為 0 (主要行程)，其餘 1, 2, ... 為備案
            }
        }

        await db.SaveChangesAsync();
        return Ok(new { status = "success", message = "備案排序與轉正更新成功" });
    }

    /// <summary>
    /// 舊版相容：行程卡片依 GroupId 重新排序
    /// </summary>
    // PUT api/schedules/reorder
    [HttpPut("reorder")]
    public async Task<IActionResult> Reorder([FromBody] ReorderRequest req)
    {
        if (!await auth.CanEditAsync(req.TripId, User))
            return StatusCode(403, new { status = "error", message = "無編輯權限" });

        var schedules = await db.Schedules
            .Where(s => s.TripId == req.TripId && s.Day == req.Day)
            .ToListAsync();

        for (int i = 0; i < req.OrderedGroupIds.Count; i++)
        {
            var groupId = req.OrderedGroupIds[i];
            foreach (var s in schedules.Where(s => s.GroupId == groupId))
                s.SortOrder = i;
        }

        await db.SaveChangesAsync();
        return Ok(new { status = "success" });
    }
}

public record AddScheduleRequest(
    Guid TripId, int Day, string? Date, string AttractionName,
    string? StartTime, string? EndTime, string? Remark,
    string? GoogleMapLink, string? ImageUrl, int SortOrder, int AltOrder, Guid? GroupId);

public record UpdateScheduleRequest(
    string? AttractionName, string? StartTime, string? EndTime,
    string? Remark, string? GoogleMapLink, string? ImageUrl, string? Date);

public record ReorderRequest(Guid TripId, int Day, List<Guid> OrderedGroupIds);
public record ReorderBackupsRequest(Guid? TripId, Guid? GroupId, List<Guid>? OrderedIds);
