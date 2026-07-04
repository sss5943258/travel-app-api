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

// 設定跨來源資源共用 (CORS) — 允許前端 React 測試環境跨網域呼叫
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
        policy.WithOrigins(
            "http://localhost:5173",   // Vite 預設 dev 伺服器
            "http://localhost:3000"    // 備用或其他常見 react 伺服器
        )
        .AllowAnyHeader()
        .AllowAnyMethod());
});

// 建立 Web 應用程式實例
var app = builder.Build();

// ── 設定 HTTP 請求管道 (Middleware 中介軟體) ───────────────────────

if (app.Environment.IsDevelopment())
{
    // 開發環境下啟用 OpenAPI endpoint
    app.MapOpenApi();

    // 開發環境下，直接自動建庫建表（免 Migration 檔案）
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

// 啟用靜態檔案服務，以便存取上傳的圖片
app.UseStaticFiles();

// 啟用 CORS
app.UseCors("AllowFrontend");

// 啟用授權 (Authorization)
app.UseAuthorization();

// 對應 Controller 路由
app.MapControllers();

// 啟動應用程式
app.Run();
