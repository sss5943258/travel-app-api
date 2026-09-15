namespace TravelApp.Api.Models;

/// <summary>
/// 旅程共編者模型，記錄具有共同編輯權限的 Google 帳號
/// </summary>
public class TripCollaborator
{
    /// <summary>
    /// 所屬旅程識別碼
    /// </summary>
    public Guid TripId { get; set; }

    /// <summary>
    /// 共編者之 Google 電子信箱 (全小寫)
    /// </summary>
    public string UserEmail { get; set; } = string.Empty;

    /// <summary>
    /// 角色 (例如 editor 或 viewer，預設 editor)
    /// </summary>
    public string Role { get; set; } = "editor";

    /// <summary>
    /// 加入共編時間
    /// </summary>
    public DateTime AddedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public Trip? Trip { get; set; }
}
