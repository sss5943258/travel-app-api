namespace TravelApp.Api.Models;

/// <summary>
/// 行程明細模型，代表某個旅程中某天的景點/活動明細
/// </summary>
public class Schedule
{
    /// <summary>
    /// 行程唯一識別碼 (主鍵)
    /// </summary>
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// 所屬的旅程識別碼 (外鍵)
    /// </summary>
    public Guid TripId { get; set; }

    /// <summary>
    /// 群組識別碼 (用於備案的關聯，同一個景點的主案與備案共享同個 GroupId)
    /// </summary>
    public Guid GroupId { get; set; }

    /// <summary>
    /// 天數 (例如第 1 天、第 2 天)
    /// </summary>
    public int Day { get; set; }

    /// <summary>
    /// 該天的日期時間字串 (yyyy-MM-dd)
    /// </summary>
    public string? Date { get; set; }

    /// <summary>
    /// 備案排序 (0 代表主方案，1、2... 代表備案)
    /// </summary>
    public int AltOrder { get; set; } = 0;

    /// <summary>
    /// 顯示順序 (同一天內多個景點的上下排序)
    /// </summary>
    public int SortOrder { get; set; } = 0;

    /// <summary>
    /// 景點或活動名稱
    /// </summary>
    public string AttractionName { get; set; } = string.Empty;

    /// <summary>
    /// 開始時間 (HH:mm)
    /// </summary>
    public string? StartTime { get; set; }

    /// <summary>
    /// 結束時間 (HH:mm)
    /// </summary>
    public string? EndTime { get; set; }

    /// <summary>
    /// 備份或提醒備註
    /// </summary>
    public string? Remark { get; set; }

    /// <summary>
    /// Google 地圖連結
    /// </summary>
    public string? GoogleMapLink { get; set; }

    /// <summary>
    /// 圖片 URL
    /// </summary>
    public string? ImageUrl { get; set; }

    // Navigation

    /// <summary>
    /// 關聯的旅程主表
    /// </summary>
    public Trip Trip { get; set; } = null!;
}

