using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;
using TravelApp.Api.Models;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 旅行攜帶品項管理 API 控制器，提供物品清單的取得、新增、刪除、及狀態切換等功能
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class PackingItemsController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// 取得所有攜帶物品清單 (依 SortOrder 與建立時間排序)
    /// </summary>
    /// <returns>攜帶物品清單</returns>
    // GET api/packingitems
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var items = await db.PackingItems
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.CreatedAt)
            .ToListAsync();

        return Ok(items);
    }

    /// <summary>
    /// 新增一筆待攜帶物品項目
    /// </summary>
    /// <param name="req">新增品項請求參數</param>
    /// <returns>新增成功的品項詳細資料</returns>
    // POST api/packingitems
    [HttpPost]
    public async Task<IActionResult> Add([FromBody] AddPackingItemRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest(new { error = "品項名稱為必填" });

        var maxSort = await db.PackingItems.MaxAsync(p => (int?)p.SortOrder) ?? 0;

        var item = new PackingItem
        {
            Name = req.Name.Trim(),
            IsEssential = req.IsEssential,
            SortOrder = maxSort + 1
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
        if (item == null) return NotFound();

        db.PackingItems.Remove(item);
        await db.SaveChangesAsync();
        return Ok(new { status = "success" });
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
        if (item == null) return NotFound();

        item.Checked = req.Checked;
        await db.SaveChangesAsync();

        return Ok(new { status = "success", itemId = id, @checked = item.Checked });
    }
}

/// <summary>
/// 新增待攜帶物品項目的 DTO 請求格式
/// </summary>
/// <param name="Name">物品名稱 (必填)</param>
/// <param name="IsEssential">是否為必備物品</param>
public record AddPackingItemRequest(string Name, bool IsEssential);

/// <summary>
/// 切換物品已確認狀態的 DTO 請求格式
/// </summary>
/// <param name="Checked">是否已勾選確認</param>
public record ToggleRequest(bool Checked);

