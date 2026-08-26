// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '搬家箱';

  @override
  String get loading => '正在读取本地数据…';

  @override
  String get retry => '重试';

  @override
  String get projects => '搬家项目';

  @override
  String get newProject => '新建项目';

  @override
  String get globalSearch => '全局搜索';

  @override
  String get archivedProjects => '已归档项目';

  @override
  String get settings => '设置';

  @override
  String get noProjects => '还没有搬家项目';

  @override
  String get noProjectsHint => '创建一个项目后，即可开始快速登记纸箱。';

  @override
  String get sampleProjectName => '示例搬家';

  @override
  String get sampleOrigin => '旧家';

  @override
  String get sampleDestination => '新家';

  @override
  String get sampleMemo => '咖啡机、杯子和滤纸';

  @override
  String get projectName => '项目名称';

  @override
  String get origin => '原位置（可选）';

  @override
  String get destination => '目标位置（可选）';

  @override
  String get boxPrefix => '箱号前缀';

  @override
  String get create => '创建';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get edit => '编辑';

  @override
  String get archive => '归档';

  @override
  String get restore => '恢复';

  @override
  String get delete => '删除';

  @override
  String get deleteProjectConfirm =>
      '删除项目后，项目内箱子记录也会一并删除。现实箱体上的旧标签可能仍然存在。是否继续？';

  @override
  String get deleteBoxConfirm => '删除记录后不会复用该箱号。现实箱体上的旧标签可能仍然存在。是否继续？';

  @override
  String boxCount(int count) {
    return '$count 个箱子';
  }

  @override
  String get quickEntry => '快速登记';

  @override
  String get takePhoto => '拍照登记';

  @override
  String get choosePhotos => '批量选照片';

  @override
  String get voiceEntry => '语音登记';

  @override
  String get manualEntry => '手动登记';

  @override
  String get photoLimit => '每批最多选择 30 张照片。';

  @override
  String batchCreated(int count, Object from, Object to) {
    return '已创建 $count 个箱子记录：$from 至 $to';
  }

  @override
  String get physicalMarkTitle => '请标记现实箱体';

  @override
  String physicalMarkMessage(Object code) {
    return '数字记录 $code 已创建。请在对应纸箱上手写箱号、粘贴便利贴或打印二维码标签。';
  }

  @override
  String physicalMarkBatchMessage(int count) {
    return '已创建 $count 个数字记录。请根据照片与箱号逐一标记现实箱体，避免错位。';
  }

  @override
  String get qrLabel => '二维码标签已粘贴';

  @override
  String get handwritten => '已手写编号';

  @override
  String get stickyNote => '已粘贴便利贴';

  @override
  String get other => '其他方式';

  @override
  String get later => '稍后处理';

  @override
  String get pendingPhysicalMark => '待实体标记';

  @override
  String get marked => '已确认标记';

  @override
  String get progress => '搬家进度';

  @override
  String get total => '总数';

  @override
  String get packed => '已打包';

  @override
  String get loaded => '已装车';

  @override
  String get arrived => '已到达';

  @override
  String get unpacked => '已拆箱';

  @override
  String get draft => '草稿';

  @override
  String get suspectedMissing => '疑似遗漏';

  @override
  String get damagedBox => '箱体损坏';

  @override
  String get damagedContents => '内容物损坏';

  @override
  String get priority => '优先拆箱';

  @override
  String get normal => '普通';

  @override
  String get searchBoxes => '搜索箱号、备注、物品、房间或标签';

  @override
  String get noResults => '没有匹配结果';

  @override
  String get boxCode => '箱号';

  @override
  String get boxTitle => '标题（可选）';

  @override
  String get destinationRoom => '目的房间（可选）';

  @override
  String get currentLocation => '当前位置（可选）';

  @override
  String get memo => '备注（可选）';

  @override
  String get tags => '标签';

  @override
  String get tagsHint => '用逗号分隔，例如：易碎, 怕潮';

  @override
  String get items => '结构化物品';

  @override
  String get itemsHint => '用逗号分隔物品名称（可选）';

  @override
  String get duplicateCode => '该箱号已在当前项目中使用';

  @override
  String get boxSaved => '箱子记录已保存';

  @override
  String get addPhoto => '添加照片';

  @override
  String get qrAndPrint => '二维码与打印';

  @override
  String get scan => '扫描箱子标签';

  @override
  String get unsupportedQr => '这不是本应用支持的箱子标签。可返回后手动搜索箱号。';

  @override
  String get boxNotFound => '标签格式正确，但本机没有对应箱子记录。';

  @override
  String get moveStatus => '搬运状态';

  @override
  String get issues => '异常标记';

  @override
  String get physicalMark => '实体标记';

  @override
  String get exportSinglePdf => '分享单个 PDF';

  @override
  String get exportPng => '分享高清 PNG';

  @override
  String get printLabel => '系统打印';

  @override
  String get exportA4Pdf => '分享全部 A4 标签';

  @override
  String get labelExportedNotice => '标签已导出，但仍需确认标签已粘贴或箱号已写到现实箱体。';

  @override
  String noPrinterHint(Object code) {
    return '没有打印机也可以继续。请将 $code 写在纸箱明显位置，或写在便利贴上粘贴到箱体。';
  }

  @override
  String get exportCsv => '导出项目 CSV';

  @override
  String get backup => '分享本地备份';

  @override
  String get restoreBackup => '从文件恢复备份';

  @override
  String get restoreWarning => '恢复会先完整校验备份；成功后替换当前本地数据。无效备份不会覆盖现有记录。';

  @override
  String get restoreSuccess => '备份恢复成功';

  @override
  String get invalidBackup => '备份无效或版本不受支持，现有数据未被修改。';

  @override
  String get privacy => '隐私说明';

  @override
  String get privacyBody =>
      '项目、箱子、备注和照片默认只保存在本机。核心功能不依赖账号、广告 SDK 或第三方 AI。二维码仅包含格式版本、项目 ID、箱子 ID 和可读箱号，不包含地址、照片或物品清单。照片、相机、麦克风和语音识别权限仅在您主动使用对应功能时请求。';

  @override
  String get about => '关于搬家箱';

  @override
  String get aboutBody => '用于快速登记纸箱、离线搜索物品并追踪搬运状态。全部功能免费，无订阅、试用倒计时或付费墙。';

  @override
  String get platformSupport => '系统要求';

  @override
  String get platformSupportBody => 'iOS 15 或更高版本；Android 14 或更高版本。';

  @override
  String get noArchived => '没有已归档项目';

  @override
  String get voiceTitle => '语音登记';

  @override
  String get voiceHint => '说出箱内物品、目的房间和注意事项。转写内容可在保存前修改。';

  @override
  String get startListening => '开始录音';

  @override
  String get stopListening => '停止录音';

  @override
  String get speechUnavailable => '语音识别暂不可用';

  @override
  String get speechUnavailableHint =>
      '设备、语言或权限可能不支持当前识别。可以立即切换为手动文字登记，不影响其他功能。';

  @override
  String get switchManual => '改用手动登记';

  @override
  String get transcript => '语音转写';

  @override
  String get createFromVoice => '创建箱子记录';

  @override
  String get voiceEmpty => '请先录入或手动输入备注';

  @override
  String get permissionDenied => '权限未授予，可改用不需要该权限的登记方式。';

  @override
  String get photoFailed => '照片处理失败，未创建对应记录。';

  @override
  String get dataError => '本地数据读取失败';

  @override
  String get editProject => '编辑项目';

  @override
  String get projectDashboard => '项目总览';

  @override
  String get boxes => '箱子';

  @override
  String get viewPending => '查看待标记';

  @override
  String get noPending => '所有箱子均已确认实体标记';

  @override
  String get markConfirmed => '确认实体标记';

  @override
  String get labelExported => '标签已导出';

  @override
  String get close => '关闭';

  @override
  String get shareCsv => '分享 CSV';

  @override
  String get shareBackup => '分享备份';

  @override
  String get createdAt => '创建时间';

  @override
  String get searchAllHint => '搜索全部项目中的箱子';

  @override
  String get projectArchived => '项目已归档';

  @override
  String get projectRestored => '项目已恢复';

  @override
  String get projectDeleted => '项目已删除';

  @override
  String get boxDeleted => '箱子记录已删除';

  @override
  String get selectMarkMethod => '选择已完成的实体标记方式';

  @override
  String get statusUpdated => '状态已更新';

  @override
  String get camera => '相机';

  @override
  String get gallery => '照片选择器';

  @override
  String get removePhoto => '移除照片';

  @override
  String get exportFailed => '导出失败，请稍后重试';

  @override
  String get share => '分享';

  @override
  String get print => '打印';

  @override
  String get allLabels => '全部标签';

  @override
  String get unknownProject => '未知项目';
}
