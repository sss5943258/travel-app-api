namespace TravelApp.Api.Models;

/// <summary>
/// 上傳圖片持久化模型，以二進位 (BYTEA) 存入 Neon PostgreSQL
/// </summary>
public class UploadedImage
{
    /// <summary>
    /// 圖片唯一識別碼 (主鍵)
    /// </summary>
    public Guid ImageId { get; set; } = Guid.NewGuid();

    /// <summary>
    /// 所屬旅程識別碼 (可選)
    /// </summary>
    public Guid? TripId { get; set; }

    /// <summary>
    /// MIME 類型 (例如 image/jpeg, image/png)
    /// </summary>
    public string ContentType { get; set; } = "image/png";

    /// <summary>
    /// 原始檔案名稱
    /// </summary>
    public string? FileName { get; set; }

    /// <summary>
    /// 圖片的原始二進位資料
    /// </summary>
    public byte[] Data { get; set; } = [];

    /// <summary>
    /// 上傳時間
    /// </summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
