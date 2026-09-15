namespace TravelApp.Api.Models;

/// <summary>
/// 旅行攜帶品項模型，記錄使用者待打包物品清單
/// </summary>
public class PackingItem
{
    /// <summary>
    /// 品項唯一識別碼 (主鍵)
    /// </summary>
    public Guid ItemId { get; set; } = Guid.NewGuid();

    /// <summary>
    /// 攜帶品項名稱
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// 是否為必備物品 (標記為 ⭐)
    /// </summary>
    public bool IsEssential { get; set; } = false;

    /// <summary>
    /// 是否已勾選/完成確認
    /// </summary>
    public bool Checked { get; set; } = false;

    /// <summary>
    /// 排序權重
    /// </summary>
    public int SortOrder { get; set; } = 0;

    /// <summary>
    /// 所屬使用者識別碼 (Google sub)
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// 建立時間
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

