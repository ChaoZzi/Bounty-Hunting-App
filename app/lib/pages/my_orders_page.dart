import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../models/order.dart';

/// ============================================================================
/// 我的任务列表页
/// ============================================================================
///
/// 【页面职责】
/// 展示当前登录用户在不同状态下的报名记录：
///   进行中 / 待审核 / 已通过 / 未通过
///
/// 【数据来源】
/// `GET /api/v1/order/my?group={group}&pageNum={n}&pageSize=10`
/// 后端调用链：AuthInterceptor → OrderController.my → TaskService.myOrders
///
/// 【交互设计】
/// - 顶部四个 Tab，切换时清空列表重新请求
/// - 下拉刷新 = 回到第 1 页重来
/// - 滚动到底部自动加载下一页
/// - 跳转采用 push，返回时列表保持现状（不强制刷新）
///
/// 【为什么用 StatefulWidget 而不是 Riverpod/Provider】
/// 这个页面没有跨页面共享的状态，所有数据都是页面私有的。
/// 引入状态管理框架只会增加一层间接，收益为零。
/// 等到出现"多个页面需要同一份数据"（比如未读数角标）时再抽。
/// ============================================================================
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  // ==========================================================================
  // 常量
  // ==========================================================================

  /// Tab 配置表：第一个元素是传给后端的 `group` 参数，第二个是显示文案。
  ///
  /// 【为什么用二维 List 而不是枚举】
  /// 这份表要同时驱动"Tab 标签"和"接口参数"两件事。
  /// 用枚举反而要写 switch 把枚举映射成字符串，多一层。
  /// 注意 group 的取值必须和后端 TaskService.myOrders 里的 case 分支一致：
  ///   doing / pending / approved / rejected
  static const List<List<String>> _tabs = [
    ['doing', '进行中'],
    ['pending', '待审核'],
    ['approved', '已通过'],
    ['rejected', '未通过'],
  ];

  /// 每页条数。后端 PageResult 有 maxLimit=200 的保护，传大也不会拖垮数据库。
  static const int _pageSize = 10;

  // ==========================================================================
  // 状态
  // ==========================================================================

  /// 列表滚动控制器，用来监听"是否快到底部"
  final ScrollController _scroll = ScrollController();

  /// 当前 Tab 已加载的数据。切 Tab 时清空。
  final List<OrderModel> _orders = [];

  /// 当前选中的 Tab 下标（0~3）
  int _tabIndex = 0;

  /// 下一个要请求的页码。
  ///
  /// 【为什么从 1 开始，首屏加载成功后置为 2】
  /// 这是一个容易写错的地方：
  ///   错误写法：请求前 _pageNum++，再请求 _pageNum，会在首屏就请求第 2 页；
  ///   正确写法：_nextPage 表示"还没请求的下一页"，请求成功后 +1。
  /// 这样即使请求失败，_nextPage 也不会被错误推进，重试仍然请求同一页。
  int _nextPage = 1;

  /// 后端是否还有下一页。为 false 时不再触发加载更多，也不再显示底部 loading。
  bool _hasNext = true;

  /// 首屏加载中（显示整页转圈）
  bool _loading = true;

  /// 加载更多中（只在列表底部显示小转圈）
  bool _loadingMore = false;

  /// 错误信息，非空时显示错误页 + 重试按钮
  String? _error;

  /// ==========================================================================
  /// 请求序号 —— 解决"快速切 Tab 导致列表串数据"的竞态问题
  /// ==========================================================================
  ///
  /// 【问题场景】
  /// 用户 0.1 秒内从「进行中」切到「待审核」：
  ///   t=0ms   发出请求 A（group=doing）
  ///   t=100ms 切 Tab，发出请求 B（group=pending）
  ///   t=300ms 请求 B 先回来，列表显示 pending ✓
  ///   t=400ms 请求 A 后回来，把列表覆盖成 doing ✗ ← 页面显示待审核 Tab，
  ///                                                  但内容是进行中的
  ///
  /// 【解法】
  /// 每次发起请求前自增序号，响应回来时比对：
  ///   如果响应携带的序号 != 当前最新序号，说明这是"过期请求"，直接丢弃。
  /// 这比"取消请求"简单（Dio 的 CancelToken 也能做，但要额外管理生命周期），
  /// 而且对用户来说结果一样——只是多消耗了一点流量。
  int _reqSeq = 0;

  // ==========================================================================
  // 生命周期
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    // 必须先移除监听再 dispose，否则某些 Flutter 版本会报
    // "A ScrollController was used after being disposed"
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  // ==========================================================================
  // 交互回调
  // ==========================================================================

  /// 滚动监听：距底部不足 240px 时预加载下一页。
  ///
  /// 【为什么是 240 而不是 0】
  /// 等滚到底再加载，用户会看到明显的"空白等待"。
  /// 提前 240px（约两张卡片的高度）触发，数据回来时用户刚好滚到。
  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 240) return;
    if (_loading || _loadingMore || !_hasNext) return;
    _loadMore();
  }

  /// 切换 Tab。
  ///
  /// 立即清空旧数据并重置分页状态，避免"新 Tab 显示旧 Tab 的数据"这一帧。
  void _switchTab(int index) {
    if (index == _tabIndex) return;
    setState(() {
      _tabIndex = index;
      _orders.clear();
      _nextPage = 1;
      _hasNext = true;
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    _reload();
  }

  // ==========================================================================
  // 数据加载
  // ==========================================================================

  /// 首屏 / 下拉刷新：从头加载第 1 页。
  Future<void> _reload() async {
    final seq = ++_reqSeq; // 抢占最新序号，之前所有在途请求就此作废

    if (!_loading) {
      setState(() => _loading = true);
    }
    setState(() => _error = null);

    try {
      final page = await _fetch(1);

      // 【两个判断缺一不可】
      // mounted：页面可能已经被 pop 掉了，此时 setState 会抛异常
      // seq != _reqSeq：这是过期请求，丢弃
      if (!mounted || seq != _reqSeq) return;

      setState(() {
        _orders
          ..clear()
          ..addAll(page.orders);
        _hasNext = page.hasNext;
        _nextPage = 2; // 第 1 页已消费，下一页是 2
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _reqSeq) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// 上拉加载更多。
  Future<void> _loadMore() async {
    final seq = _reqSeq; // 记录当前所属的"请求世代"
    setState(() => _loadingMore = true);

    try {
      final page = await _fetch(_nextPage);
      if (!mounted) return;

      // 如果在加载更多期间用户切了 Tab，_reqSeq 会变，这次结果必须丢弃，
      // 否则会把上一个 Tab 的数据追加到新列表里。
      if (seq != _reqSeq) {
        setState(() => _loadingMore = false);
        return;
      }

      setState(() {
        _orders.addAll(page.orders);
        _hasNext = page.hasNext;
        _nextPage += 1;
        _loadingMore = false;
      });
    } catch (_) {
      // 加载更多失败不弹错误页——已经显示的内容还有效，
      // 静默失败即可，用户继续滚动会再次触发。
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  /// 真正发请求的地方，返回 (列表, 是否还有下一页)。
  ///
  /// 用私有小类 _OrderPage 而不是 Record，是为了让类型签名更可读；
  /// 如果团队统一用 Record 也可以，Dart 3 支持 `(List<OrderModel>, bool)`。
  Future<_OrderPage> _fetch(int pageNum) async {
    final data = await Api.get('/order/my', query: {
      'group': _tabs[_tabIndex][0],
      'pageNum': pageNum,
      'pageSize': _pageSize,
    });

    // Api.get 返回的是响应体里的 data 字段（dynamic），这里转成 Map 才能安全取值
    final map = Map<String, dynamic>.from(data as Map);

    final orders = ((map['list'] as List?) ?? [])
        // 逐条转模型。这里用 Map.from 而不是直接 as Map<String, dynamic>，
        // 是因为 Dio 有时给出的是 Map<dynamic, dynamic>（尤其经过 isolate 后）
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return _OrderPage(orders, map['hasNext'] == true);
  }

  // ==========================================================================
  // 构建
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的任务')),
      body: Column(
        children: [
          _tabBar(),
          // Expanded 让列表占满剩余空间，否则 ListView 拿不到高度约束会报错
          Expanded(child: _body()),
        ],
      ),
    );
  }

  /// 顶部四个 Tab。
  ///
  /// 【为什么不用 TabBar/TabBarView】
  /// TabBarView 会同时保活多个子页，每个子页各自维护分页状态，
  /// 结果是四处都要写一遍 loading/分页逻辑。
  /// 这里单列表 + 单状态机，切 Tab 只是换 group 重新请求，代码量少一半。
  /// 代价是切回来要重新加载——对 10 条一页的数据量，这点开销无所谓。
  Widget _tabBar() {
    return SizedBox(
      height: 46,
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final active = i == _tabIndex;
          return Expanded(
            child: GestureDetector(
              // opaque 让整块区域（含下方空白）都响应点击，
              // 否则只有文字本身可点，手感很差
              behavior: HitTestBehavior.opaque,
              onTap: () => _switchTab(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _tabs[i][1],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppColors.gold300 : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 金色下划线，宽度 0→20 的动画让切换有"生长"感
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 20 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.gold500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 按状态分发到：加载中 / 错误 / 空 / 列表
  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold500),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _reload, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Text('还没有记录', style: TextStyle(color: AppColors.textTertiary)),
      );
    }

    return RefreshIndicator(
      color: AppColors.gold500,
      backgroundColor: AppColors.bgElevated,
      onRefresh: _reload,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        // 有下一页时多渲染一个 item 作为底部 loading 占位
        itemCount: _orders.length + (_hasNext ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i >= _orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold500,
                  ),
                ),
              ),
            );
          }
          return _orderCard(_orders[i]);
        },
      ),
    );
  }

  /// 单条订单卡片
  Widget _orderCard(OrderModel o) {
    return DarkCard(
      // 订单详情页放到后续功能，先留空
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- 第一行：标题 + 金额 ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // 必须包 Expanded，否则长标题会把金额挤出屏幕
                child: Text(
                  o.taskTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                // toStringAsFixed(2) 保证 3.2 显示成 3.20，和人民币习惯一致
                '¥${o.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ---------- 第二行：状态徽章 + 报名时间 ----------
          Row(
            children: [
              _statusBadge(o),
              const SizedBox(width: 8),
              Text(
                '报名于 ${o.applyText}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),

          // ---------- 进行中：倒计时 + 提交按钮 ----------
          // Dart 的集合 if 语法：条件成立时才把这个元素加入 children
          if (o.isDoing && o.remainText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  o.remainText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
                const Spacer(), // 把按钮推到最右
                _submitButton(),
              ],
            ),
          ],

          // ---------- 驳回：显示原因 ----------
          if (o.isRejected && o.reviewRemark.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '驳回原因：${o.reviewRemark}',
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  /// 状态徽章。
  ///
  /// 用 Dart 3 的 switch 表达式 + Record 一次性返回颜色和文案，
  /// 比"先判断颜色再判断文案"两段 if 更好维护。
  Widget _statusBadge(OrderModel o) {
    final (Color color, String text) = switch (o.status) {
      OrderModel.statusDoing => (AppColors.info, '进行中'),
      OrderModel.statusReviewing => (AppColors.warning, '待审核'),

      // 3 已通过 / 6 已结算，对用户都是"过了"，合并展示
      OrderModel.statusApproved || OrderModel.statusSettled => (
          AppColors.success,
          '已通过',
        ),

      // 4 驳回 / 5 超时，用后端下发的文案区分（"未通过" / "已超时"）
      OrderModel.statusRejected || OrderModel.statusTimeout => (
          AppColors.danger,
          o.statusText,
        ),

      // 兜底：后端新增了状态而前端还没跟上时，至少显示原始文案
      _ => (AppColors.textTertiary, o.statusText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // alpha 0.14 的浅色底 + 同色文字，是深色界面的标准徽章做法
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  /// 「去提交」按钮 —— 目前是占位，功能 2 接这里
  Widget _submitButton() {
    return GestureDetector(
      onTap: () {
        // TODO(f02): 跳转到提交凭证页，参数为 orderNo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交功能还没做，下一版接上')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gold700),
        ),
        child: const Text(
          '去提交',
          style: TextStyle(fontSize: 12, color: AppColors.gold300),
        ),
      ),
    );
  }
}

/// 一次分页请求的结果。
///
/// 单独定义而不直接用 `(List<OrderModel>, bool)`，是因为后者在调用处
/// 会变成 `page.$1` / `page.$2`，可读性差。
class _OrderPage {
  final List<OrderModel> orders;
  final bool hasNext;

  const _OrderPage(this.orders, this.hasNext);
}
