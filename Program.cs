using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using TravelApp.Api.Data;
using TravelApp.Api.Services;

// 初始化 Web 應用程式建構器
var builder = WebApplication.CreateBuilder(args);

// ── 註冊服務到 DI 容器 ─────────────────────────────────────────

// 註冊 HttpClient 供 Google Token 驗證等外網通訊使用
builder.Services.AddHttpClient();

// 註冊權限驗證服務
builder.Services.AddScoped<TripAuthService>();

// 註冊 Controller 控制器
builder.Services.AddControllers()
    .AddJsonOptions(o =>
        o.JsonSerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles);

// 註冊 OpenAPI (Swagger) 文件生成服務
builder.Services.AddOpenApi();

// 註冊 PostgreSQL 資料庫上下文 (EF Core)
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// 設定 JWT Bearer 身份驗證服務
var rawJwtSecret = builder.Configuration["Jwt:Secret"];
var jwtSecret = !string.IsNullOrWhiteSpace(rawJwtSecret)
    ? rawJwtSecret
    : "travel-app-dev-fallback-secret-key-must-be-at-least-256-bits-long!";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "TravelApp.Api";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "TravelApp.Client";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });
builder.Services.AddAuthorization();

// 設定跨來源資源共用 (CORS) — 允許前端 React 測試環境與 GitHub Pages 正式網域呼叫
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
        policy.SetIsOriginAllowed(origin =>
            // 允許本機 vite 或其他本地 port
            origin.StartsWith("http://localhost:") ||
            origin.StartsWith("https://localhost:") ||
            // 允許 GitHub Pages 網域 (*.github.io)
            origin.EndsWith(".github.io"))
        .AllowAnyHeader()
        .AllowAnyMethod());
});

// 建立 Web 應用程式實例
var app = builder.Build();

// ── 設定 HTTP 請求管道 (Middleware 中介軟體) ───────────────────────

// 開發或雲端環境啟動時：自動確保資料庫結構存在，並執行具等冪性 (idempotent) 的 seed.sql 確保新資料表與欄位皆同步
try
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();

    var seedPath = Path.Combine(app.Environment.ContentRootPath, "seed.sql");
    if (File.Exists(seedPath))
    {
        var sql = File.ReadAllText(seedPath);
        db.Database.ExecuteSqlRaw(sql);
    }
}
catch (Exception ex)
{
    Console.WriteLine($"[DB 初始化警告] {ex.Message}");
}

if (app.Environment.IsDevelopment())
{
    // 開發環境下啟用 OpenAPI endpoint
    app.MapOpenApi();
}

// 啟用靜態檔案服務
app.UseStaticFiles();

// 啟用 CORS
app.UseCors("AllowFrontend");

// 啟用身份驗證 (Authentication) 與授權 (Authorization)
app.UseAuthentication();
app.UseAuthorization();

// 健康檢查與資料庫連線診斷端點
app.MapGet("/health", async (AppDbContext db) =>
{
    try
    {
        var canConnect = await db.Database.CanConnectAsync();
        return Results.Ok(new { status = "healthy", db = canConnect ? "connected" : "disconnected", timestamp = DateTime.UtcNow });
    }
    catch (Exception ex)
    {
        return Results.Ok(new { status = "healthy", db = "error", error = ex.Message, timestamp = DateTime.UtcNow });
    }
});

// 對應 Controller 路由
app.MapControllers();

// 啟動應用程式
app.Run();
