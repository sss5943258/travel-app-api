namespace TravelApp.Api.Models;

/// <summary>
/// 使用者登入 Session 與 RefreshToken 模型
/// </summary>
public class UserSession
{
    /// <summary>
    /// Session 識別碼 (主鍵)
    /// </summary>
    public Guid SessionId { get; set; } = Guid.NewGuid();

    /// <summary>
    /// 所屬的使用者識別碼 (外鍵)
    /// </summary>
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// 刷新權杖 (RefreshToken)
    /// </summary>
    public string RefreshToken { get; set; } = string.Empty;

    /// <summary>
    /// 刷新權杖過期時間
    /// </summary>
    public DateTime RefreshExpiresAt { get; set; }

    /// <summary>
    /// 是否已被手動撤銷/登出
    /// </summary>
    public bool IsRevoked { get; set; } = false;

    /// <summary>
    /// 建立時間
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public User? User { get; set; }
}
