using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Data;

// 初始化 Web 應用程式建構器
var builder = WebApplication.CreateBuilder(args);

// ── 註冊服務到 DI 容器 ─────────────────────────────────────────

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

// 開發或雲端環境啟動時：自動確保資料庫結構存在，並在全空時自動注入 seed.sql 範例資料
try
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();

    if (!db.Trips.Any())
    {
        var seedPath = Path.Combine(app.Environment.ContentRootPath, "seed.sql");
        if (File.Exists(seedPath))
        {
            var sql = File.ReadAllText(seedPath);
            db.Database.ExecuteSqlRaw(sql);
        }
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

// 啟用靜態檔案服務，以便存取上傳的圖片
app.UseStaticFiles();

// 啟用 CORS
app.UseCors("AllowFrontend");

// 啟用授權 (Authorization)
app.UseAuthorization();

// 健康檢查端點 (Keep-Alive 用，提供 UptimeRobot 定期 ping 避免 Render 雲端休眠)
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// 對應 Controller 路由
app.MapControllers();

// 啟動應用程式
app.Run();
