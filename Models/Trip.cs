namespace TravelApp.Api.Models;

/// <summary>
/// 旅程主表模型，記錄旅程基本資訊
/// </summary>
public class Trip
{
    /// <summary>
    /// 旅程唯一識別碼 (主鍵)
    /// </summary>
    public Guid TripId { get; set; } = Guid.NewGuid();

    /// <summary>
    /// 唯讀分享用的 UUID，防止外部直接猜出主鍵或進行編輯
    /// </summary>
    public Guid ReadOnlyId { get; set; } = Guid.NewGuid();

    /// <summary>
    /// 旅程名稱
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// 出發日期 (yyyy-MM-dd)
    /// </summary>
    public string? StartDate { get; set; }

    /// <summary>
    /// 回程日期 (yyyy-MM-dd)
    /// </summary>
    public string? EndDate { get; set; }

    /// <summary>
    /// 旅程封面圖 URL
    /// </summary>
    public string? CoverUrl { get; set; }

    /// <summary>
    /// 擁有者使用者識別碼 (Google sub)
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// 建立時間
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation

    /// <summary>
    /// 關聯的旅程航班與備註資訊 (1對1)
    /// </summary>
    public TripInfo? TripInfo { get; set; }

    /// <summary>
    /// 關聯的行程明細清單 (1對多)
    /// </summary>
    public ICollection<Schedule> Schedules { get; set; } = [];

    /// <summary>
    /// 關聯的共編者名單 (1對多)
    /// </summary>
    public ICollection<TripCollaborator> Collaborators { get; set; } = [];
}

