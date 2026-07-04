using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 行程明細管理 API 控制器，提供行程項目的新增、編輯、刪除與重新排序等功能
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class SchedulesController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// 新增一筆行程卡片項目 (或是為既有行程新增備案)
    /// </summary>
    /// <param name="req">行程新增請求參數</param>
    /// <returns>新增成功的 ID</returns>
    // POST api/schedules
    [HttpPost]
    public async Task<IActionResult> Add([FromBody] AddScheduleRequest req)
    {
        if (!await db.Trips.AnyAsync(t => t.TripId == req.TripId))
            return NotFound(new { error = "找不到旅程" });

        var groupId = req.GroupId ?? Guid.NewGuid();
        var schedule = new Schedule
        {
            TripId = req.TripId,
            GroupId = groupId,
            Day = req.Day,
            Date = req.Date,
            AttractionName = req.AttractionName,
            StartTime = req.StartTime,
            EndTime = req.EndTime,
            Remark = req.Remark,
            GoogleMapLink = req.GoogleMapLink,
            SortOrder = req.SortOrder,
            AltOrder = req.AltOrder
        };

        db.Schedules.Add(schedule);
        await db.SaveChangesAsync();

        return Ok(new { status = "success", id = schedule.Id });
    }

    /// <summary>
    /// 更新特定行程明細內容 (例如時間、景點名稱、備註等)
    /// </summary>
    /// <param name="id">行程 ID</param>
    /// <param name="req">更新參數</param>
    /// <returns>成功狀態</returns>
    // PUT api/schedules/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateScheduleRequest req)
    {
        var schedule = await db.Schedules.FindAsync(id);
        if (schedule == null) return NotFound();

        schedule.AttractionName = req.AttractionName ?? schedule.AttractionName;
        schedule.StartTime = req.StartTime ?? schedule.StartTime;
        schedule.EndTime = req.EndTime ?? schedule.EndTime;
        schedule.Remark = req.Remark ?? schedule.Remark;
        schedule.GoogleMapLink = req.GoogleMapLink ?? schedule.GoogleMapLink;

        await db.SaveChangesAsync();
        return Ok(new { status = "success" });
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
        if (schedule == null) return NotFound();

        db.Schedules.Remove(schedule);
        await db.SaveChangesAsync();
        return Ok(new { status = "success" });
    }

    /// <summary>
    /// 行程重新排序 (拖曳調整卡片順序後呼叫，更新特定旅程特定天數的所有群組 SortOrder)
    /// </summary>
    /// <param name="req">重新排序參數 (包含重排後的 GroupId 順序清單)</param>
    /// <returns>成功狀態</returns>
    // PUT api/schedules/reorder
    [HttpPut("reorder")]
    public async Task<IActionResult> Reorder([FromBody] ReorderRequest req)
    {
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

/// <summary>
/// 新增行程的 DTO 請求格式
/// </summary>
public record AddScheduleRequest(
    Guid TripId, int Day, string? Date, string AttractionName,
    string? StartTime, string? EndTime, string? Remark,
    string? GoogleMapLink, int SortOrder, int AltOrder, Guid? GroupId);

/// <summary>
/// 更新行程的 DTO 請求格式 (可選更新欄位)
/// </summary>
public record UpdateScheduleRequest(
    string? AttractionName, string? StartTime, string? EndTime,
    string? Remark, string? GoogleMapLink);

/// <summary>
/// 重新排序行程的 DTO 請求格式
/// </summary>
public record ReorderRequest(Guid TripId, int Day, List<Guid> OrderedGroupIds);

