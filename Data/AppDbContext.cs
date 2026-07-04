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
        });
    }
}

