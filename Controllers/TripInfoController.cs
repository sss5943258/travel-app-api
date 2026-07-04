using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 旅程詳細航班資訊與備註管理 API 控制器，提供更新（或新增）旅程航班詳細內容的功能
/// </summary>
[ApiController]
[Route("api/trips/{tripId:guid}/info")]
public class TripInfoController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// 更新或新增旅程詳細航班與備註資訊 (若對應的 TripInfo 不存在則新增，存在則進行部分更新)
    /// </summary>
    /// <param name="tripId">旅程 ID</param>
    /// <param name="req">更新參數 (只會更新有傳入非空值的屬性)</param>
    /// <returns>成功狀態</returns>
    // PUT api/trips/{tripId}/info
    [HttpPut]
    public async Task<IActionResult> Upsert(Guid tripId, [FromBody] TripInfoRequest req)
    {
        if (!await db.Trips.AnyAsync(t => t.TripId == tripId))
            return NotFound(new { error = "找不到旅程" });

        var info = await db.TripInfos.FindAsync(tripId);

        if (info == null)
        {
            info = new TripInfo { TripId = tripId };
            db.TripInfos.Add(info);
        }

        // 只更新有傳入的欄位
        if (req.OutboundFlightNo is not null)   info.OutboundFlightNo = req.OutboundFlightNo;
        if (req.OutboundAirline is not null)     info.OutboundAirline = req.OutboundAirline;
        if (req.OutboundDepartureTime is not null) info.OutboundDepartureTime = req.OutboundDepartureTime;
        if (req.OutboundArrivalTime is not null) info.OutboundArrivalTime = req.OutboundArrivalTime;
        if (req.OutboundDepAirport is not null)  info.OutboundDepAirport = req.OutboundDepAirport;
        if (req.OutboundArrAirport is not null)  info.OutboundArrAirport = req.OutboundArrAirport;
        if (req.OutboundFlightRemark is not null) info.OutboundFlightRemark = req.OutboundFlightRemark;
        if (req.OutboundImageUrl is not null)    info.OutboundImageUrl = req.OutboundImageUrl;
        if (req.InboundFlightNo is not null)     info.InboundFlightNo = req.InboundFlightNo;
        if (req.InboundAirline is not null)      info.InboundAirline = req.InboundAirline;
        if (req.InboundDepartureTime is not null) info.InboundDepartureTime = req.InboundDepartureTime;
        if (req.InboundArrivalTime is not null)  info.InboundArrivalTime = req.InboundArrivalTime;
        if (req.InboundDepAirport is not null)   info.InboundDepAirport = req.InboundDepAirport;
        if (req.InboundArrAirport is not null)   info.InboundArrAirport = req.InboundArrAirport;
        if (req.InboundFlightRemark is not null) info.InboundFlightRemark = req.InboundFlightRemark;
        if (req.InboundImageUrl is not null)     info.InboundImageUrl = req.InboundImageUrl;
        if (req.TripRemark is not null)          info.TripRemark = req.TripRemark;

        await db.SaveChangesAsync();
        return Ok(new { status = "success" });
    }

    /// <summary>
    /// 上傳圖片至本地 (以 base64 傳入並解碼儲存於 wwwroot/uploads/)
    /// </summary>
    /// <param name="tripId">旅程 ID</param>
    /// <param name="req">上傳請求參數</param>
    /// <returns>回傳上傳後的圖片網址</returns>
    // POST api/trips/{tripId}/info/upload
    [HttpPost("upload")]
    public async Task<IActionResult> Upload(Guid tripId, [FromBody] UploadImageRequest req)
    {
        if (!await db.Trips.AnyAsync(t => t.TripId == tripId))
            return NotFound(new { error = "找不到旅程" });

        if (string.IsNullOrEmpty(req.ImageBase64))
            return BadRequest(new { error = "缺少圖片資料" });

        try
        {
            // 解析 Base64，移除 data:image/png;base64, 等前綴
            var base64Parts = req.ImageBase64.Split(',');
            var base64Data = base64Parts.Length > 1 ? base64Parts[1] : base64Parts[0];
            var bytes = Convert.FromBase64String(base64Data);

            // 確保 wwwroot/uploads 目錄存在
            var uploadDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            if (!Directory.Exists(uploadDir))
            {
                Directory.CreateDirectory(uploadDir);
            }

            var extension = Path.GetExtension(req.FileName) ?? ".png";
            if (string.IsNullOrEmpty(extension)) extension = ".png";
            var newFileName = $"{tripId}_{req.Type}_{DateTime.UtcNow.Ticks}{extension}";
            var filePath = Path.Combine(uploadDir, newFileName);

            await System.IO.File.WriteAllBytesAsync(filePath, bytes);

            // 組合靜態網址
            var request = HttpContext.Request;
            var host = request.Host.Value;
            var scheme = request.Scheme;
            var imageUrl = $"{scheme}://{host}/uploads/{newFileName}";

            return Ok(new { status = "success", imageUrl });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = $"圖片儲存失敗: {ex.Message}" });
        }
    }
}

/// <summary>
/// 更新或新增旅程詳細資訊的 DTO 請求格式 (包含去回程航班、時間、機場、備註等)
/// </summary>
public record TripInfoRequest(
    string? OutboundFlightNo, string? OutboundAirline,
    string? OutboundDepartureTime, string? OutboundArrivalTime,
    string? OutboundDepAirport, string? OutboundArrAirport,
    string? OutboundFlightRemark, string? OutboundImageUrl,
    string? InboundFlightNo, string? InboundAirline,
    string? InboundDepartureTime, string? InboundArrivalTime,
    string? InboundDepAirport, string? InboundArrAirport,
    string? InboundFlightRemark, string? InboundImageUrl,
    string? TripRemark);

/// <summary>
/// 上傳圖片的 DTO 請求格式
/// </summary>
/// <param name="Type">類型 (outbound 或 inbound)</param>
/// <param name="ImageBase64">圖片的 Base64 編碼字串</param>
/// <param name="FileName">原始檔案名稱</param>
public record UploadImageRequest(string Type, string ImageBase64, string FileName);

