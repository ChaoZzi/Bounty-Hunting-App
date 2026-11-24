import 'package:flutter_test/flutter_test.dart';

import 'package:bounty_app/models/order.dart';

/// 订单模型的单元测试。
///
/// 选这个文件做第一个测试，是因为它没有 UI、没有网络、没有 BuildContext，
/// 是最容易被测试覆盖、也最容易在重构时被改坏的一层。
void main() {
  group('OrderModel.fromJson', () {
    test('完整字段能正确解析', () {
      final model = OrderModel.fromJson({
        'orderNo': 'TO202611132113465292',
        'taskId': 4,
        'taskTitle': '试玩小游戏通关前三关',
        'taskCover': '',
        'amount': 3.2,
        'status': 1,
        'statusText': '进行中',
        'applyAt': '2026-11-13 21:13:46',
        'deadlineAt': '2026-11-15 21:13:46',
        'reviewRemark': '',
      });

      expect(model.orderNo, 'TO202611132113465292');
      expect(model.taskId, 4);
      expect(model.amount, 3.2);
      expect(model.isDoing, isTrue);
      // 空格分隔的时间要能被解析出来
      expect(model.applyAt, isNotNull);
      expect(model.applyAt!.hour, 21);
      expect(model.deadlineAt, isNotNull);
    });

    test('缺字段时降级为空值而不是抛异常', () {
      final model = OrderModel.fromJson({'orderNo': 'X'});

      expect(model.taskTitle, '');
      expect(model.amount, 0);
      expect(model.status, 0);
      expect(model.applyAt, isNull);
      expect(model.isDoing, isFalse);
    });

    test('金额是整数时也能转成 double', () {
      final model = OrderModel.fromJson({'amount': 3});
      expect(model.amount, 3.0);
    });

    test('非法时间字符串返回 null', () {
      final model = OrderModel.fromJson({'applyAt': 'not-a-date'});
      expect(model.applyAt, isNull);
      expect(model.applyText, '');
    });
  });

  group('状态判断', () {
    test('3 已通过 和 6 已结算 都算通过', () {
      expect(OrderModel.fromJson({'status': 3}).isApproved, isTrue);
      expect(OrderModel.fromJson({'status': 6}).isApproved, isTrue);
    });

    test('4 驳回 和 5 超时 都算未通过', () {
      expect(OrderModel.fromJson({'status': 4}).isRejected, isTrue);
      expect(OrderModel.fromJson({'status': 5}).isRejected, isTrue);
    });

    test('只有进行中才显示倒计时文案', () {
      final future = DateTime.now().add(const Duration(hours: 3));
      final text = future.toIso8601String().replaceFirst('T', ' ').split('.').first;

      final doing = OrderModel.fromJson({'status': 1, 'deadlineAt': text});
      expect(doing.remainText, contains('小时'));

      final reviewing = OrderModel.fromJson({
        'status': 2,
        'deadlineAt': '2026-11-15 21:13:46',
      });
      expect(reviewing.remainText, '');
    });
  });
}
