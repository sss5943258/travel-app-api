using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;
using TravelApp.Api.Services;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 旅行攜帶品項管理 API 控制器，提供個人物品清單的取得、新增、刪除、及狀態切換等功能 (支援多租戶資料隔離)
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class PackingItemsController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// 取得當前登入者的攜帶物品清單 (依 SortOrder 與建立時間排序)
    /// </summary>
    /// <returns>攜帶物品清單</returns>
    // GET api/packingitems
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var currentUserId = TripAuthService.GetUserId(User);

        var query = db.PackingItems.AsNoTracking();

        // 若有登入者，篩選屬於該使用者或是尚未綁定使用者的通用預設物品
        if (!string.IsNullOrEmpty(currentUserId))
        {
            query = query.Where(p => p.UserId == currentUserId || p.UserId == null);
        }

        var items = await query
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.CreatedAt)
            .ToListAsync();

        return Ok(items);
    }

    /// <summary>
    /// 新增一筆待攜帶物品項目 (自動綁定當前登入使用者)
    /// </summary>
    /// <param name="req">新增品項請求參數</param>
    /// <returns>新增成功的品項詳細資料</returns>
    // POST api/packingitems
    [HttpPost]
    public async Task<IActionResult> Add([FromBody] AddPackingItemRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest(new { status = "error", message = "品項名稱為必填" });

        var currentUserId = TripAuthService.GetUserId(User);

        var maxSort = await db.PackingItems
            .Where(p => p.UserId == currentUserId)
            .MaxAsync(p => (int?)p.SortOrder) ?? 0;

        var item = new PackingItem
        {
            ItemId = Guid.NewGuid(),
            Name = req.Name.Trim(),
            IsEssential = req.IsEssential,
            SortOrder = maxSort + 1,
            UserId = currentUserId,
            CreatedAt = DateTime.UtcNow
        };

        db.PackingItems.Add(item);
        await db.SaveChangesAsync();

        return Ok(new { status = "success", item });
    }

    /// <summary>
    /// 刪除特定攜帶物品項目
    /// </summary>
    /// <param name="id">品項 ID</param>
    /// <returns>成功狀態</returns>
    // DELETE api/packingitems/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var item = await db.PackingItems.FindAsync(id);
        if (item == null) return NotFound(new { status = "error", message = "找不到此物品" });

        var currentUserId = TripAuthService.GetUserId(User);
        if (!string.IsNullOrEmpty(item.UserId) && item.UserId != currentUserId)
        {
            return StatusCode(403, new { status = "error", message = "無權限刪除其他人的行李品項" });
        }

        db.PackingItems.Remove(item);
        await db.SaveChangesAsync();
        return Ok(new { status = "success", message = "物品已刪除" });
    }

    /// <summary>
    /// 切換攜帶物品項目的勾選狀態 (已確認 / 未確認)
    /// </summary>
    /// <param name="id">品項 ID</param>
    /// <param name="req">切換狀態參數</param>
    /// <returns>更新後的狀態</returns>
    // PATCH api/packingitems/{id}/toggle
    [HttpPatch("{id:guid}/toggle")]
    public async Task<IActionResult> Toggle(Guid id, [FromBody] ToggleRequest req)
    {
        var item = await db.PackingItems.FindAsync(id);
        if (item == null) return NotFound(new { status = "error", message = "找不到此物品" });

        var currentUserId = TripAuthService.GetUserId(User);
        if (!string.IsNullOrEmpty(item.UserId) && item.UserId != currentUserId)
        {
            return StatusCode(403, new { status = "error", message = "無權限編輯其他人的行李品項" });
        }

        item.Checked = req.Checked;
        await db.SaveChangesAsync();

        return Ok(new { status = "success", itemId = id, @checked = item.Checked });
    }
}

public record AddPackingItemRequest(string Name, bool IsEssential);
public record ToggleRequest(bool Checked);
