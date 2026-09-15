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

        // 依 Day 分組並保全空天數 (Day 1 ~ Day N)
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
    /// 建立一趟新旅程 (不預塞任何佔位卡片，每一天均為乾淨空天數)
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

