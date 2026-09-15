using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;

namespace TravelApp.Api.Services;

/// <summary>
/// 旅程權限驗證輔助服務，負責檢查當前使用者對旅程的擁有權與共編權限
/// </summary>
public class TripAuthService(AppDbContext db)
{
    /// <summary>
    /// 從 HttpContext 的 ClaimsPrincipal 取得當前登入者之 Google UserId (sub)
    /// </summary>
    public static string? GetUserId(ClaimsPrincipal user)
    {
        return user.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? user.FindFirst("sub")?.Value;
    }

    /// <summary>
    /// 從 HttpContext 的 ClaimsPrincipal 取得當前登入者之 Email
    /// </summary>
    public static string? GetUserEmail(ClaimsPrincipal user)
    {
        return user.FindFirst(ClaimTypes.Email)?.Value
            ?? user.FindFirst("email")?.Value;
    }

    /// <summary>
    /// 檢查使用者是否為旅程擁有者 (Owner)
    /// </summary>
    public async Task<bool> IsOwnerAsync(Guid tripId, ClaimsPrincipal user)
    {
        var userId = GetUserId(user);
        if (string.IsNullOrEmpty(userId)) return false;

        var trip = await db.Trips.FindAsync(tripId);
        if (trip == null) return false;

        // 若為最初 seed 的公開範例旅程 (UserId 為 null) 允許編輯
        if (string.IsNullOrEmpty(trip.UserId)) return true;

        return trip.UserId == userId;
    }

    /// <summary>
    /// 檢查使用者是否具備旅程編輯權限 (擁有者或受邀共編者)
    /// </summary>
    public async Task<bool> CanEditAsync(Guid tripId, ClaimsPrincipal user)
    {
        var userId = GetUserId(user);
        var email = GetUserEmail(user)?.ToLowerInvariant();

        var trip = await db.Trips.FindAsync(tripId);
        if (trip == null) return false;

        // 範例旅程 (未綁定擁有者) 允許編輯
        if (string.IsNullOrEmpty(trip.UserId)) return true;

        // 是擁有者
        if (!string.IsNullOrEmpty(userId) && trip.UserId == userId) return true;

        // 是共編者
        if (!string.IsNullOrEmpty(email))
        {
            var isCollaborator = await db.TripCollaborators
                .AnyAsync(c => c.TripId == tripId && c.UserEmail == email);
            if (isCollaborator) return true;
        }

        return false;
    }
}
