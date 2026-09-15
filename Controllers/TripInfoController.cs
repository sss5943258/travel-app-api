using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;
using TravelApp.Api.Services;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 旅程詳細航班資訊與備註管理 API 控制器，提供更新（或新增）旅程航班詳細內容的功能
/// </summary>
[ApiController]
[Route("api/trips/{tripId:guid}/info")]
public class TripInfoController(AppDbContext db, TripAuthService auth) : ControllerBase
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

        if (!await auth.CanEditAsync(tripId, User))
            return StatusCode(403, new { error = "無編輯權限或非此旅程擁有者/共編者" });

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
    /// 上傳圖片並持久化儲存於 Neon 資料庫中 (解決 Render 免費容器休眠重啟時丟圖問題)
    /// </summary>
    /// <param name="tripId">旅程 ID</param>
    /// <param name="req">上傳請求參數</param>
    /// <returns>回傳上傳後的持久化圖片網址</returns>
    // POST api/trips/{tripId}/info/upload
    [HttpPost("upload")]
    public async Task<IActionResult> Upload(Guid tripId, [FromBody] UploadImageRequest req)
    {
        if (!await db.Trips.AnyAsync(t => t.TripId == tripId))
            return NotFound(new { error = "找不到旅程" });

        if (!await auth.CanEditAsync(tripId, User))
            return StatusCode(403, new { error = "無編輯權限或非此旅程擁有者/共編者" });

        if (string.IsNullOrEmpty(req.ImageBase64))
            return BadRequest(new { error = "缺少圖片資料" });

        try
        {
            // 解析 Base64
            var base64Parts = req.ImageBase64.Split(',');
            var contentType = "image/png";

            if (base64Parts.Length > 1)
            {
                var match = System.Text.RegularExpressions.Regex.Match(base64Parts[0], @"data:(.*?);");
                if (match.Success) contentType = match.Groups[1].Value;
            }

            var base64Data = base64Parts.Length > 1 ? base64Parts[1] : base64Parts[0];
            var bytes = Convert.FromBase64String(base64Data);

            // 存入 Neon PostgreSQL UploadedImages 資料表
            var uploadedImage = new UploadedImage
            {
                TripId = tripId,
                ContentType = contentType,
                FileName = req.FileName,
                Data = bytes,
                CreatedAt = DateTime.UtcNow
            };
            db.UploadedImages.Add(uploadedImage);

            // 組合 API 圖片網址
            var request = HttpContext.Request;
            var host = request.Host.Value;
            var scheme = request.Scheme;
            var imageUrl = $"{scheme}://{host}/api/images/{uploadedImage.ImageId}";

            // 同步寫入對應的 TripInfo 欄位
            var info = await db.TripInfos.FindAsync(tripId);
            if (info == null)
            {
                info = new TripInfo { TripId = tripId };
                db.TripInfos.Add(info);
            }

            var fieldName = req.Type == "outbound" ? "outboundImageUrl" : "inboundImageUrl";
            if (req.Type == "outbound")
            {
                info.OutboundImageUrl = imageUrl;
            }
            else
            {
                info.InboundImageUrl = imageUrl;
            }

            await db.SaveChangesAsync();

            return Ok(new
            {
                status = "success",
                message = "圖片上傳成功",
                imageUrl,
                fieldName
            });
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

