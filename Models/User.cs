namespace TravelApp.Api.Models;

/// <summary>
/// 使用者模型，對應 Google 帳號授權資訊
/// </summary>
public class User
{
    /// <summary>
    /// Google sub 唯一識別碼 (主鍵)
    /// </summary>
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// 使用者 Google 電子信箱
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// 使用者名稱
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// 使用者大頭照 URL
    /// </summary>
    public string? Picture { get; set; }

    /// <summary>
    /// 帳號初次建立時間
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// 最後登入時間
    /// </summary>
    public DateTime LastLoginAt { get; set; } = DateTime.UtcNow;
}
