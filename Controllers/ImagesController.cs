using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 圖片管理與靜態輸出 API 控制器，從 Neon PostgreSQL 資料庫中串流讀取二進位圖片
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class ImagesController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// 依據圖片 ID 取得原始二進位圖片串流 (支援公開唯讀存取，並設定瀏覽器快取)
    /// </summary>
    /// <param name="id">圖片 ID</param>
    /// <returns>圖片檔案串流</returns>
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    [ResponseCache(Duration = 86400, Location = ResponseCacheLocation.Any)] // 快取 1 天
    public async Task<IActionResult> GetImage(Guid id)
    {
        var img = await db.UploadedImages
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.ImageId == id);

        if (img == null || img.Data.Length == 0)
        {
            return NotFound();
        }

        return File(img.Data, img.ContentType);
    }
}
