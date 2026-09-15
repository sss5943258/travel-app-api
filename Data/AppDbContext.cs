using Microsoft.EntityFrameworkCore;
using TravelApp.Api.Models;

namespace TravelApp.Api.Data;

/// <summary>
/// 應用程式資料庫上下文，繼承自 Entity Framework Core DbContext
/// </summary>
/// <param name="options">資料庫連接與配置設定</param>
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    /// <summary>
    /// 旅程資料表
    /// </summary>
    public DbSet<Trip> Trips => Set<Trip>();

    /// <summary>
    /// 旅程詳細與航班資訊資料表
    /// </summary>
    public DbSet<TripInfo> TripInfos => Set<TripInfo>();

    /// <summary>
    /// 行程明細資料表
    /// </summary>
    public DbSet<Schedule> Schedules => Set<Schedule>();

    /// <summary>
    /// 旅行攜帶品項資料表
    /// </summary>
    public DbSet<PackingItem> PackingItems => Set<PackingItem>();

    /// <summary>
    /// 使用者資料表 (Google 授權帳號)
    /// </summary>
    public DbSet<User> Users => Set<User>();

    /// <summary>
    /// 使用者登入 Session 與 RefreshToken 資料表
    /// </summary>
    public DbSet<UserSession> UserSessions => Set<UserSession>();

    /// <summary>
    /// 旅程共編者資料表
    /// </summary>
    public DbSet<TripCollaborator> TripCollaborators => Set<TripCollaborator>();

    /// <summary>
    /// 上傳圖片二進位持久化資料表
    /// </summary>
    public DbSet<UploadedImage> UploadedImages => Set<UploadedImage>();

    /// <summary>
    /// 設定 Entity 之間的關聯、索引與欄位約束
    /// </summary>
    /// <param name="modelBuilder">模型建構器</param>
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Trip 關聯與屬性設定
        modelBuilder.Entity<Trip>(e =>
        {
            e.HasKey(t => t.TripId);
            e.Property(t => t.Name).IsRequired().HasMaxLength(200);
            e.HasIndex(t => t.ReadOnlyId).IsUnique(); // 唯讀分享識別碼必需唯一且建立索引以加速查詢
            e.HasIndex(t => t.UserId); // 依使用者查詢旅程加速
        });

        // TripInfo — 設定與 Trip 之間的一對一關聯 (1:1 with Trip)
        modelBuilder.Entity<TripInfo>(e =>
        {
            e.HasKey(t => t.TripId);
            e.HasOne(t => t.Trip)
             .WithOne(t => t.TripInfo)
             .HasForeignKey<TripInfo>(t => t.TripId)
             .OnDelete(DeleteBehavior.Cascade); // 刪除旅程時一併刪除此詳細資訊
        });

        // Schedule — 設定與 Trip 之間的一對多關聯及複合索引
        modelBuilder.Entity<Schedule>(e =>
        {
            e.HasKey(s => s.Id);
            e.Property(s => s.AttractionName).IsRequired().HasMaxLength(300);
            e.HasOne(s => s.Trip)
             .WithMany(t => t.Schedules)
             .HasForeignKey(s => s.TripId)
             .OnDelete(DeleteBehavior.Cascade); // 刪除旅程時一併刪除其所有行程
            e.HasIndex(s => new { s.TripId, s.Day, s.SortOrder }); // 依據旅程ID、天數、排序建立複合索引，優化撈行程的速度
        });

        // PackingItem 欄位限制設定
        modelBuilder.Entity<PackingItem>(e =>
        {
            e.HasKey(p => p.ItemId);
            e.Property(p => p.Name).IsRequired().HasMaxLength(200);
            e.HasIndex(p => p.UserId); // 依使用者篩選行李清單加速
        });

        // User 使用者約束設定
        modelBuilder.Entity<User>(e =>
        {
            e.HasKey(u => u.UserId);
            e.HasIndex(u => u.Email).IsUnique();
        });

        // UserSession 階段約束設定
        modelBuilder.Entity<UserSession>(e =>
        {
            e.HasKey(s => s.SessionId);
            e.HasIndex(s => s.RefreshToken).IsUnique();
            e.HasOne(s => s.User)
             .WithMany()
             .HasForeignKey(s => s.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // TripCollaborator 旅程共編者約束設定 (複合主鍵)
        modelBuilder.Entity<TripCollaborator>(e =>
        {
            e.HasKey(c => new { c.TripId, c.UserEmail });
            e.Property(c => c.UserEmail).IsRequired().HasMaxLength(200);
            e.HasOne(c => c.Trip)
             .WithMany(t => t.Collaborators)
             .HasForeignKey(c => c.TripId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // UploadedImage 上傳圖片約束設定
        modelBuilder.Entity<UploadedImage>(e =>
        {
            e.HasKey(i => i.ImageId);
        });
    }
}

