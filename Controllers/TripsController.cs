using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 旅程管理 API 控制器，提供旅程的建立、查詢、刪除等功能
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class TripsController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// 取得所有旅程清單 (依建立時間由新到舊排序)
    /// </summary>
    /// <returns>旅程清單</returns>
    // GET api/trips
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var trips = await db.Trips
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new
            {
                t.TripId,
                t.ReadOnlyId,
                t.Name,
                t.StartDate,
                t.EndDate,
                t.CoverUrl
            })
            .ToListAsync();

        return Ok(trips);
    }

    /// <summary>
    /// 取得特定旅程的詳細內容與每日行程分組 (支援可編輯 UUID 或唯讀 UUID 查詢)
    /// </summary>
    /// <param name="id">旅程的 UUID (tripId 或 readOnlyId)</param>
    /// <returns>旅程詳細資料</returns>
    // GET api/trips/{id}  (支援 tripId 或 readOnlyId)
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        // 先找 tripId
        var trip = await db.Trips
            .Include(t => t.TripInfo)
            .Include(t => t.Schedules)
            .FirstOrDefaultAsync(t => t.TripId == id);

        bool isReadOnly = false;

        // 找不到再找 readOnlyId
        if (trip == null)
        {
            trip = await db.Trips
                .Include(t => t.TripInfo)
                .Include(t => t.Schedules)
                .FirstOrDefaultAsync(t => t.ReadOnlyId == id);

            if (trip == null)
                return NotFound(new { error = $"找不到 tripId: {id}" });

            isReadOnly = true;
        }

        // 依 Day 分組
        var journeys = trip.Schedules
            .OrderBy(s => s.Day).ThenBy(s => s.SortOrder)
            .GroupBy(s => s.Day)
            .Select(g => new
            {
                Day = g.Key,
                Date = g.First().Date,
                Schedule = g.Select(s => new
                {
                    s.Id,
                    s.GroupId,
                    s.TripId,
                    s.Day,
                    s.Date,
                    s.AltOrder,
                    s.SortOrder,
                    s.AttractionName,
                    s.StartTime,
                    s.EndTime,
                    s.Remark,
                    s.GoogleMapLink,
                    s.ImageUrl
                })
            });

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
    /// 建立一趟新旅程，若有提供起迄日期，會自動生成每日行程的佔位卡片
    /// </summary>
    /// <param name="req">建立旅程請求參數</param>
    /// <returns>新增成功的狀態與 UUIDs</returns>
    // POST api/trips
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTripRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest(new { error = "行程名稱為必填" });

        var trip = new Trip
        {
            Name = req.Name.Trim(),
            StartDate = req.StartDate,
            EndDate = req.EndDate
        };

        db.Trips.Add(trip);

        // 自動產生每日佔位 schedule
        if (!string.IsNullOrEmpty(req.StartDate) && !string.IsNullOrEmpty(req.EndDate)
            && DateTime.TryParse(req.StartDate, out var start)
            && DateTime.TryParse(req.EndDate, out var end))
        {
            int totalDays = (int)(end - start).TotalDays + 1;
            for (int i = 0; i < totalDays; i++)
            {
                var date = start.AddDays(i);
                var groupId = Guid.NewGuid();
                db.Schedules.Add(new Schedule
                {
                    TripId = trip.TripId,
                    GroupId = groupId,
                    Day = i + 1,
                    Date = date.ToString("yyyy-MM-dd"),
                    AttractionName = "（待新增）",
                    SortOrder = 0,
                    AltOrder = 0
                });
            }
        }

        await db.SaveChangesAsync();
        return Ok(new { status = "success", tripId = trip.TripId, readOnlyId = trip.ReadOnlyId });
    }

    /// <summary>
    /// 刪除一趟旅程 (會一併級聯刪除對應的航班資訊與行程明細)
    /// </summary>
    /// <param name="id">旅程 ID</param>
    /// <returns>成功狀態訊息</returns>
    // DELETE api/trips/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var trip = await db.Trips.FindAsync(id);
        if (trip == null) return NotFound();

        db.Trips.Remove(trip); // Cascade 會一起刪 TripInfo 和 Schedules
        await db.SaveChangesAsync();
        return Ok(new { status = "success", message = "行程已刪除" });
    }
}

/// <summary>
/// 建立旅程的 DTO 請求格式
/// </summary>
/// <param name="Name">旅程名稱 (必填)</param>
/// <param name="StartDate">出發日期 yyyy-MM-dd</param>
/// <param name="EndDate">回程日期 yyyy-MM-dd</param>
public record CreateTripRequest(string Name, string? StartDate, string? EndDate);

