namespace TravelApp.Api.Models;

/// <summary>
/// 旅程詳細資訊模型，記錄去回程航班、照片與備註 (1對1關聯)
/// </summary>
public class TripInfo
{
    /// <summary>
    /// 旅程對應的主鍵 (同時作為外鍵與主鍵)
    /// </summary>
    public Guid TripId { get; set; }

    /// <summary>
    /// 去程航班號碼
    /// </summary>
    public string? OutboundFlightNo { get; set; }

    /// <summary>
    /// 去程航空公司
    /// </summary>
    public string? OutboundAirline { get; set; }

    /// <summary>
    /// 去程出發時間
    /// </summary>
    public string? OutboundDepartureTime { get; set; }

    /// <summary>
    /// 去程抵達時間
    /// </summary>
    public string? OutboundArrivalTime { get; set; }

    /// <summary>
    /// 去程出發機場
    /// </summary>
    public string? OutboundDepAirport { get; set; }

    /// <summary>
    /// 去程抵達機場
    /// </summary>
    public string? OutboundArrAirport { get; set; }

    /// <summary>
    /// 去程航班備註
    /// </summary>
    public string? OutboundFlightRemark { get; set; }

    /// <summary>
    /// 去程機票/資訊截圖 URL
    /// </summary>
    public string? OutboundImageUrl { get; set; }

    /// <summary>
    /// 回程航班號碼
    /// </summary>
    public string? InboundFlightNo { get; set; }

    /// <summary>
    /// 回程航空公司
    /// </summary>
    public string? InboundAirline { get; set; }

    /// <summary>
    /// 回程出發時間
    /// </summary>
    public string? InboundDepartureTime { get; set; }

    /// <summary>
    /// 回程抵達時間
    /// </summary>
    public string? InboundArrivalTime { get; set; }

    /// <summary>
    /// 回程出發機場
    /// </summary>
    public string? InboundDepAirport { get; set; }

    /// <summary>
    /// 回程抵達機場
    /// </summary>
    public string? InboundArrAirport { get; set; }

    /// <summary>
    /// 回程航班備註
    /// </summary>
    public string? InboundFlightRemark { get; set; }

    /// <summary>
    /// 回程機票/資訊截圖 URL
    /// </summary>
    public string? InboundImageUrl { get; set; }

    /// <summary>
    /// 整趟旅程的綜合備註
    /// </summary>
    public string? TripRemark { get; set; }

    // Navigation

    /// <summary>
    /// 關聯的旅程主表 (1對1)
    /// </summary>
    public Trip Trip { get; set; } = null!;
}

