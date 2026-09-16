using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using TravelApp.Api.Data;
using TravelApp.Api.Models;

namespace TravelApp.Api.Controllers;

/// <summary>
/// 認證管理 API 控制器，提供 Google OAuth 登入、Token 刷新與登出功能
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController(
    AppDbContext db,
    IConfiguration config,
    IHttpClientFactory httpClientFactory) : ControllerBase
{
    /// <summary>
    /// 以 Google ID Token 進行登入，驗證成功後發行 AccessToken (JWT) 與 RefreshToken
    /// </summary>
    /// <param name="req">包含 Google idToken 的請求物件</param>
    /// <returns>包含 token 與使用者資訊的登入結果</returns>
    [HttpPost("google")]
    [AllowAnonymous]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.IdToken))
            return BadRequest(new { status = "error", message = "缺少 idToken 參數" });

        // 1. 呼叫 Google tokeninfo API 驗證 token 真實性
        var client = httpClientFactory.CreateClient();
        var googleVerifyUrl = $"https://oauth2.googleapis.com/tokeninfo?id_token={Uri.EscapeDataString(req.IdToken)}";
        var response = await client.GetAsync(googleVerifyUrl);

        if (!response.IsSuccessStatusCode)
        {
            return Unauthorized(new { status = "error", message = "Google id_token 驗證失敗，token 可能已過期或無效" });
        }

        var jsonStr = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(jsonStr);
        var root = doc.RootElement;

        var aud = root.TryGetProperty("aud", out var audProp) ? audProp.GetString() : null;
        var expectedClientId = config["Google:ClientId"];

        // 驗證 Audience 是否符合系統設定的 ClientId
        if (!string.IsNullOrEmpty(expectedClientId) && aud != expectedClientId)
        {
            return Unauthorized(new { status = "error", message = "Google id_token audience 不符，拒絕登入" });
        }

        var userId = root.GetProperty("sub").GetString()!;
        var email = root.GetProperty("email").GetString()!.ToLowerInvariant();
        var name = root.TryGetProperty("name", out var nameProp) ? nameProp.GetString() : email;
        var picture = root.TryGetProperty("picture", out var picProp) ? picProp.GetString() : null;

        // 2. 查詢或建立使用者
        var user = await db.Users.FindAsync(userId);
        if (user == null)
        {
            user = new User
            {
                UserId = userId,
                Email = email,
                Name = name ?? email,
                Picture = picture,
                CreatedAt = DateTime.UtcNow,
                LastLoginAt = DateTime.UtcNow
            };
            db.Users.Add(user);
        }
        else
        {
            user.Email = email;
            user.Name = name ?? user.Name;
            user.Picture = picture ?? user.Picture;
            user.LastLoginAt = DateTime.UtcNow;
        }

        // 3. 建立 Refresh Session (有效期限 30 天)
        var refreshToken = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N");
        var session = new UserSession
        {
            UserId = userId,
            RefreshToken = refreshToken,
            RefreshExpiresAt = DateTime.UtcNow.AddDays(30),
            IsRevoked = false,
            CreatedAt = DateTime.UtcNow
        };
        db.UserSessions.Add(session);
        await db.SaveChangesAsync();

        // 4. 簽發 JWT AccessToken (有效期限 15 分鐘)
        var (accessToken, accessExpiresAt) = GenerateJwtToken(user);

        return Ok(new
        {
            status = "success",
            accessToken,
            refreshToken,
            accessExpiresAt = accessExpiresAt.ToString("o"),
            user = new
            {
                userId = user.UserId,
                email = user.Email,
                name = user.Name,
                picture = user.Picture
            }
        });
    }

    /// <summary>
    /// 以 RefreshToken 換取全新的 AccessToken (支援前端無感刷新)
    /// </summary>
    /// <param name="req">包含 refreshToken 的請求物件</param>
    /// <returns>新的 AccessToken 與過期時間</returns>
    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.RefreshToken))
            return BadRequest(new { status = "error", message = "缺少 refreshToken" });

        var session = await db.UserSessions
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.RefreshToken == req.RefreshToken);

        if (session == null || session.IsRevoked)
        {
            return Unauthorized(new { status = "error", code = "TOKEN_REVOKED", message = "Refresh Token 已失效，請重新登入" });
        }

        if (session.RefreshExpiresAt < DateTime.UtcNow)
        {
            return Unauthorized(new { status = "error", code = "TOKEN_EXPIRED", message = "登入已過期，請重新登入" });
        }

        var user = session.User;
        if (user == null)
        {
            return Unauthorized(new { status = "error", message = "找不到對應使用者" });
        }

        var (accessToken, accessExpiresAt) = GenerateJwtToken(user);

        return Ok(new
        {
            status = "success",
            accessToken,
            accessExpiresAt = accessExpiresAt.ToString("o")
        });
    }

    /// <summary>
    /// 登出系統並撤銷目前的 Session
    /// </summary>
    /// <param name="req">登出請求物件 (可帶入 refreshToken)</param>
    /// <returns>登出結果</returns>
    [HttpPost("logout")]
    [AllowAnonymous]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest? req)
    {
        if (req != null && !string.IsNullOrWhiteSpace(req.RefreshToken))
        {
            var session = await db.UserSessions
                .FirstOrDefaultAsync(s => s.RefreshToken == req.RefreshToken);
            if (session != null)
            {
                session.IsRevoked = true;
                await db.SaveChangesAsync();
            }
        }

        return Ok(new { status = "success", message = "已成功登出" });
    }

    /// <summary>
    /// 產生 JWT Access Token 的內部輔助方法
    /// </summary>
    /// <param name="user">使用者實體</param>
    /// <returns>Token 字串與過期時間</returns>
    private (string token, DateTime expiresAt) GenerateJwtToken(User user)
    {
        var rawSecret = config["Jwt:Secret"];
        var secret = !string.IsNullOrWhiteSpace(rawSecret)
            ? rawSecret
            : "travel-app-dev-fallback-secret-key-must-be-at-least-256-bits-long!";
        var issuer = config["Jwt:Issuer"] ?? "TravelApp.Api";
        var audience = config["Jwt:Audience"] ?? "TravelApp.Client";

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var expiresAt = DateTime.UtcNow.AddMinutes(15);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.UserId),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new("name", user.Name),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var jwt = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: creds
        );

        return (new JwtSecurityTokenHandler().WriteToken(jwt), expiresAt);
    }
}

public record GoogleLoginRequest(string IdToken);
public record RefreshTokenRequest(string RefreshToken);
public record LogoutRequest(string? RefreshToken, string? AccessToken);
