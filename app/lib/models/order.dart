/// ============================================================================
/// 订单模型（前后端数据契约的客户端映射）
/// ============================================================================
///
/// 【职责】
/// 把后端 `GET /order/my` 返回的 JSON 转成强类型对象，并在这一层收敛所有
/// "展示用"的派生逻辑（状态判断、倒计时文案、日期格式化）。
///
/// 【为什么派生逻辑放这里，不放 Widget 里】
/// 1. 同一份派生逻辑（比如"是否进行中"）在列表、徽章、按钮三处都要用，
///    放 Widget 里会导致三份重复判断，改一处漏两处。
/// 2. 模型是纯 Dart，没有 BuildContext，可以被单元测试直接覆盖。
/// 3. Widget 只负责"画"，不负责"算"，职责边界清楚。
///
/// 【数据来源】
/// 后端 `OrderVO`（server/bounty-service/.../vo/OrderVO.java）字段一一对应，
/// 后端加了字段这里要同步加，否则前端拿不到。
/// ============================================================================
class OrderModel {
  /// 业务单号，全局唯一，用作列表 key 和后端接口的路径参数
  final String orderNo;

  /// 关联的任务 ID，跳详情页时用
  final int taskId;

  /// 任务标题（后端由 TaskService 关联 t_task 表补上，订单表本身不存）
  final String taskTitle;

  /// 任务封面图 URL，可能为空字符串（当前演示数据都没封面）
  final String taskCover;

  /// 本单赏金金额，单位元。后端是 BigDecimal，JSON 里是数字，这里转 double
  final double amount;

  /// 订单状态码，取值见下方状态常量表
  final int status;

  /// 后端下发的状态中文文案，边缘状态用它兜底，避免前端映射表落后于后端
  final String statusText;

  /// 报名时间
  final DateTime? applyAt;

  /// 完成截止时间 = 报名时间 + 任务的 deadlineMinutes
  final DateTime? deadlineAt;

  /// 审核意见 / 驳回原因，仅驳回时有值
  final String reviewRemark;

  const OrderModel({
    required this.orderNo,
    required this.taskId,
    required this.taskTitle,
    required this.taskCover,
    required this.amount,
    required this.status,
    required this.statusText,
    this.applyAt,
    this.deadlineAt,
    this.reviewRemark = '',
  });

  // ==========================================================================
  // 状态码常量
  // --------------------------------------------------------------------------
  // 与后端 TaskOrder 的 STATUS_* 常量、数据库 t_task_order.status 的注释
  // 必须保持一致。三处任何一处改动，另外两处要同步。
  //
  //   0 待接单   (未使用，报名即进入 1)
  //   1 进行中   → 用户可提交凭证
  //   2 待审核   → 等悬赏主/平台审核
  //   3 已通过   → 尚未打款
  //   4 已驳回   → 可重新报名
  //   5 已超时   → 可重新报名
  //   6 已结算   → 钱已到账
  //   7 已取消   → 用户主动放弃
  // ==========================================================================
  static const int statusDoing = 1;
  static const int statusReviewing = 2;
  static const int statusApproved = 3;
  static const int statusRejected = 4;
  static const int statusTimeout = 5;
  static const int statusSettled = 6;

  // ==========================================================================
  // JSON 反序列化
  // ==========================================================================

  /// 从后端 JSON 构造模型。
  ///
  /// 所有字段都用 `?? ''` / `?? 0` 兜底，原因：
  /// 后端可能因为版本差异少发某个字段，前端不该因为一个 null 就整页崩溃。
  /// 这是"防御式解析"——宁可显示空字符串，也不要红屏。
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderNo: (json['orderNo'] ?? '').toString(),

      // 后端 long 类型在 JSON 里可能是 int，也可能被某些序列化器写成 String，
      // 用 `as num?` 而不是 `as int?` 更稳，再 .toInt() 归一化。
      taskId: (json['taskId'] as num?)?.toInt() ?? 0,

      taskTitle: (json['taskTitle'] ?? '').toString(),
      taskCover: (json['taskCover'] ?? '').toString(),

      // BigDecimal 序列化成 3.2 这样的数字，可能带小数也可能被写成 3，
      // 所以用 num 再转 double。
      amount: (json['amount'] as num?)?.toDouble() ?? 0,

      status: (json['status'] as num?)?.toInt() ?? 0,
      statusText: (json['statusText'] ?? '').toString(),

      applyAt: _toDate(json['applyAt']),
      deadlineAt: _toDate(json['deadlineAt']),

      reviewRemark: (json['reviewRemark'] ?? '').toString(),
    );
  }

  /// 把后端的时间字符串转成 DateTime。
  ///
  /// 【为什么需要 replaceFirst(' ', 'T')】
  /// 后端 Jackson 配置的日期格式是 `yyyy-MM-dd HH:mm:ss`（空格分隔），
  /// 而 Dart 的 DateTime.parse 遵循 ISO-8601，要求 `yyyy-MM-ddTHH:mm:ss`。
  /// 直接把空格换成 T 即可，不需要引入 intl 包解析。
  ///
  /// 【为什么用 tryParse 而不是 parse】
  /// parse 遇到格式异常会抛异常，一个字段脏了整页就崩；
  /// tryParse 返回 null，上层用 "报名于 " 空串降级显示，不影响其他内容。
  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
  }

  // ==========================================================================
  // 派生状态（供 UI 判断，避免 UI 里散落魔法数字）
  // ==========================================================================

  /// 进行中：只有这个状态才显示倒计时和「去提交」按钮
  bool get isDoing => status == statusDoing;

  /// 待审核：用户已提交，等结果
  bool get isReviewing => status == statusReviewing;

  /// 已通过：包含"审核通过未打款"和"已结算"两种，对用户来说都是"过了"
  bool get isApproved => status == statusApproved || status == statusSettled;

  /// 未通过：驳回和超时合并展示，因为对用户来说都是"这事没成"
  bool get isRejected => status == statusRejected || status == statusTimeout;

  // ==========================================================================
  // 派生展示文案
  // ==========================================================================

  /// 剩余时间文案。
  ///
  /// 【为什么不用 Timer 每秒刷新】
  /// 列表里可能有几十条订单，每条挂一个 Timer 是灾难。
  /// 这里只在构建时算一次，精度到"分钟"足够——用户不需要看秒。
  /// 需要秒级精度的是详情页的倒计时，那里再单独用 Timer。
  ///
  /// 【为什么超时要自己判断】
  /// 后端每分钟才跑一次关单任务，最长有 60 秒窗口期状态还是"进行中"，
  /// 但 deadline 已经过了。前端用 deadline 判断可以先于后端变红提示。
  String get remainText {
    if (deadlineAt == null || !isDoing) return '';
    final diff = deadlineAt!.difference(DateTime.now());
    if (diff.isNegative) return '已超时';
    if (diff.inDays > 0) return '剩余 ${diff.inDays} 天 ${diff.inHours % 24} 小时';
    if (diff.inHours > 0) return '剩余 ${diff.inHours} 小时 ${diff.inMinutes % 60} 分';
    return '剩余 ${diff.inMinutes} 分钟';
  }

  /// 报名时间简写，形如 `11-14 09:05`。
  ///
  /// 列表里空间有限，年份和秒没有信息量，去掉反而更好读。
  String get applyText {
    if (applyAt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(applyAt!.month)}-${two(applyAt!.day)} '
        '${two(applyAt!.hour)}:${two(applyAt!.minute)}';
  }
}
