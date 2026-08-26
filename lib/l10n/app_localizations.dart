import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'搬家箱'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'正在读取本地数据…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @projects.
  ///
  /// In zh, this message translates to:
  /// **'搬家项目'**
  String get projects;

  /// No description provided for @newProject.
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get newProject;

  /// No description provided for @globalSearch.
  ///
  /// In zh, this message translates to:
  /// **'全局搜索'**
  String get globalSearch;

  /// No description provided for @archivedProjects.
  ///
  /// In zh, this message translates to:
  /// **'已归档项目'**
  String get archivedProjects;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @noProjects.
  ///
  /// In zh, this message translates to:
  /// **'还没有搬家项目'**
  String get noProjects;

  /// No description provided for @noProjectsHint.
  ///
  /// In zh, this message translates to:
  /// **'创建一个项目后，即可开始快速登记纸箱。'**
  String get noProjectsHint;

  /// No description provided for @sampleProjectName.
  ///
  /// In zh, this message translates to:
  /// **'示例搬家'**
  String get sampleProjectName;

  /// No description provided for @sampleOrigin.
  ///
  /// In zh, this message translates to:
  /// **'旧家'**
  String get sampleOrigin;

  /// No description provided for @sampleDestination.
  ///
  /// In zh, this message translates to:
  /// **'新家'**
  String get sampleDestination;

  /// No description provided for @sampleMemo.
  ///
  /// In zh, this message translates to:
  /// **'咖啡机、杯子和滤纸'**
  String get sampleMemo;

  /// No description provided for @projectName.
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get projectName;

  /// No description provided for @origin.
  ///
  /// In zh, this message translates to:
  /// **'原位置（可选）'**
  String get origin;

  /// No description provided for @destination.
  ///
  /// In zh, this message translates to:
  /// **'目标位置（可选）'**
  String get destination;

  /// No description provided for @boxPrefix.
  ///
  /// In zh, this message translates to:
  /// **'箱号前缀'**
  String get boxPrefix;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get archive;

  /// No description provided for @restore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get restore;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除项目后，项目内箱子记录也会一并删除。现实箱体上的旧标签可能仍然存在。是否继续？'**
  String get deleteProjectConfirm;

  /// No description provided for @deleteBoxConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除记录后不会复用该箱号。现实箱体上的旧标签可能仍然存在。是否继续？'**
  String get deleteBoxConfirm;

  /// No description provided for @boxCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个箱子'**
  String boxCount(int count);

  /// No description provided for @quickEntry.
  ///
  /// In zh, this message translates to:
  /// **'快速登记'**
  String get quickEntry;

  /// No description provided for @takePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照登记'**
  String get takePhoto;

  /// No description provided for @choosePhotos.
  ///
  /// In zh, this message translates to:
  /// **'批量选照片'**
  String get choosePhotos;

  /// No description provided for @voiceEntry.
  ///
  /// In zh, this message translates to:
  /// **'语音登记'**
  String get voiceEntry;

  /// No description provided for @manualEntry.
  ///
  /// In zh, this message translates to:
  /// **'手动登记'**
  String get manualEntry;

  /// No description provided for @photoLimit.
  ///
  /// In zh, this message translates to:
  /// **'每批最多选择 30 张照片。'**
  String get photoLimit;

  /// No description provided for @batchCreated.
  ///
  /// In zh, this message translates to:
  /// **'已创建 {count} 个箱子记录：{from} 至 {to}'**
  String batchCreated(int count, Object from, Object to);

  /// No description provided for @physicalMarkTitle.
  ///
  /// In zh, this message translates to:
  /// **'请标记现实箱体'**
  String get physicalMarkTitle;

  /// No description provided for @physicalMarkMessage.
  ///
  /// In zh, this message translates to:
  /// **'数字记录 {code} 已创建。请在对应纸箱上手写箱号、粘贴便利贴或打印二维码标签。'**
  String physicalMarkMessage(Object code);

  /// No description provided for @physicalMarkBatchMessage.
  ///
  /// In zh, this message translates to:
  /// **'已创建 {count} 个数字记录。请根据照片与箱号逐一标记现实箱体，避免错位。'**
  String physicalMarkBatchMessage(int count);

  /// No description provided for @qrLabel.
  ///
  /// In zh, this message translates to:
  /// **'二维码标签已粘贴'**
  String get qrLabel;

  /// No description provided for @handwritten.
  ///
  /// In zh, this message translates to:
  /// **'已手写编号'**
  String get handwritten;

  /// No description provided for @stickyNote.
  ///
  /// In zh, this message translates to:
  /// **'已粘贴便利贴'**
  String get stickyNote;

  /// No description provided for @other.
  ///
  /// In zh, this message translates to:
  /// **'其他方式'**
  String get other;

  /// No description provided for @later.
  ///
  /// In zh, this message translates to:
  /// **'稍后处理'**
  String get later;

  /// No description provided for @pendingPhysicalMark.
  ///
  /// In zh, this message translates to:
  /// **'待实体标记'**
  String get pendingPhysicalMark;

  /// No description provided for @marked.
  ///
  /// In zh, this message translates to:
  /// **'已确认标记'**
  String get marked;

  /// No description provided for @progress.
  ///
  /// In zh, this message translates to:
  /// **'搬家进度'**
  String get progress;

  /// No description provided for @total.
  ///
  /// In zh, this message translates to:
  /// **'总数'**
  String get total;

  /// No description provided for @packed.
  ///
  /// In zh, this message translates to:
  /// **'已打包'**
  String get packed;

  /// No description provided for @loaded.
  ///
  /// In zh, this message translates to:
  /// **'已装车'**
  String get loaded;

  /// No description provided for @arrived.
  ///
  /// In zh, this message translates to:
  /// **'已到达'**
  String get arrived;

  /// No description provided for @unpacked.
  ///
  /// In zh, this message translates to:
  /// **'已拆箱'**
  String get unpacked;

  /// No description provided for @draft.
  ///
  /// In zh, this message translates to:
  /// **'草稿'**
  String get draft;

  /// No description provided for @suspectedMissing.
  ///
  /// In zh, this message translates to:
  /// **'疑似遗漏'**
  String get suspectedMissing;

  /// No description provided for @damagedBox.
  ///
  /// In zh, this message translates to:
  /// **'箱体损坏'**
  String get damagedBox;

  /// No description provided for @damagedContents.
  ///
  /// In zh, this message translates to:
  /// **'内容物损坏'**
  String get damagedContents;

  /// No description provided for @priority.
  ///
  /// In zh, this message translates to:
  /// **'优先拆箱'**
  String get priority;

  /// No description provided for @normal.
  ///
  /// In zh, this message translates to:
  /// **'普通'**
  String get normal;

  /// No description provided for @searchBoxes.
  ///
  /// In zh, this message translates to:
  /// **'搜索箱号、备注、物品、房间或标签'**
  String get searchBoxes;

  /// No description provided for @noResults.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配结果'**
  String get noResults;

  /// No description provided for @boxCode.
  ///
  /// In zh, this message translates to:
  /// **'箱号'**
  String get boxCode;

  /// No description provided for @boxTitle.
  ///
  /// In zh, this message translates to:
  /// **'标题（可选）'**
  String get boxTitle;

  /// No description provided for @destinationRoom.
  ///
  /// In zh, this message translates to:
  /// **'目的房间（可选）'**
  String get destinationRoom;

  /// No description provided for @currentLocation.
  ///
  /// In zh, this message translates to:
  /// **'当前位置（可选）'**
  String get currentLocation;

  /// No description provided for @memo.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get memo;

  /// No description provided for @tags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get tags;

  /// No description provided for @tagsHint.
  ///
  /// In zh, this message translates to:
  /// **'用逗号分隔，例如：易碎, 怕潮'**
  String get tagsHint;

  /// No description provided for @items.
  ///
  /// In zh, this message translates to:
  /// **'结构化物品'**
  String get items;

  /// No description provided for @itemsHint.
  ///
  /// In zh, this message translates to:
  /// **'用逗号分隔物品名称（可选）'**
  String get itemsHint;

  /// No description provided for @duplicateCode.
  ///
  /// In zh, this message translates to:
  /// **'该箱号已在当前项目中使用'**
  String get duplicateCode;

  /// No description provided for @boxSaved.
  ///
  /// In zh, this message translates to:
  /// **'箱子记录已保存'**
  String get boxSaved;

  /// No description provided for @addPhoto.
  ///
  /// In zh, this message translates to:
  /// **'添加照片'**
  String get addPhoto;

  /// No description provided for @qrAndPrint.
  ///
  /// In zh, this message translates to:
  /// **'二维码与打印'**
  String get qrAndPrint;

  /// No description provided for @scan.
  ///
  /// In zh, this message translates to:
  /// **'扫描箱子标签'**
  String get scan;

  /// No description provided for @unsupportedQr.
  ///
  /// In zh, this message translates to:
  /// **'这不是本应用支持的箱子标签。可返回后手动搜索箱号。'**
  String get unsupportedQr;

  /// No description provided for @boxNotFound.
  ///
  /// In zh, this message translates to:
  /// **'标签格式正确，但本机没有对应箱子记录。'**
  String get boxNotFound;

  /// No description provided for @moveStatus.
  ///
  /// In zh, this message translates to:
  /// **'搬运状态'**
  String get moveStatus;

  /// No description provided for @issues.
  ///
  /// In zh, this message translates to:
  /// **'异常标记'**
  String get issues;

  /// No description provided for @physicalMark.
  ///
  /// In zh, this message translates to:
  /// **'实体标记'**
  String get physicalMark;

  /// No description provided for @exportSinglePdf.
  ///
  /// In zh, this message translates to:
  /// **'分享单个 PDF'**
  String get exportSinglePdf;

  /// No description provided for @exportPng.
  ///
  /// In zh, this message translates to:
  /// **'分享高清 PNG'**
  String get exportPng;

  /// No description provided for @printLabel.
  ///
  /// In zh, this message translates to:
  /// **'系统打印'**
  String get printLabel;

  /// No description provided for @exportA4Pdf.
  ///
  /// In zh, this message translates to:
  /// **'分享全部 A4 标签'**
  String get exportA4Pdf;

  /// No description provided for @labelExportedNotice.
  ///
  /// In zh, this message translates to:
  /// **'标签已导出，但仍需确认标签已粘贴或箱号已写到现实箱体。'**
  String get labelExportedNotice;

  /// No description provided for @noPrinterHint.
  ///
  /// In zh, this message translates to:
  /// **'没有打印机也可以继续。请将 {code} 写在纸箱明显位置，或写在便利贴上粘贴到箱体。'**
  String noPrinterHint(Object code);

  /// No description provided for @exportCsv.
  ///
  /// In zh, this message translates to:
  /// **'导出项目 CSV'**
  String get exportCsv;

  /// No description provided for @backup.
  ///
  /// In zh, this message translates to:
  /// **'分享本地备份'**
  String get backup;

  /// No description provided for @restoreBackup.
  ///
  /// In zh, this message translates to:
  /// **'从文件恢复备份'**
  String get restoreBackup;

  /// No description provided for @restoreWarning.
  ///
  /// In zh, this message translates to:
  /// **'恢复会先完整校验备份；成功后替换当前本地数据。无效备份不会覆盖现有记录。'**
  String get restoreWarning;

  /// No description provided for @restoreSuccess.
  ///
  /// In zh, this message translates to:
  /// **'备份恢复成功'**
  String get restoreSuccess;

  /// No description provided for @invalidBackup.
  ///
  /// In zh, this message translates to:
  /// **'备份无效或版本不受支持，现有数据未被修改。'**
  String get invalidBackup;

  /// No description provided for @privacy.
  ///
  /// In zh, this message translates to:
  /// **'隐私说明'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In zh, this message translates to:
  /// **'项目、箱子、备注和照片默认只保存在本机。核心功能不依赖账号、广告 SDK 或第三方 AI。二维码仅包含格式版本、项目 ID、箱子 ID 和可读箱号，不包含地址、照片或物品清单。照片、相机、麦克风和语音识别权限仅在您主动使用对应功能时请求。'**
  String get privacyBody;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于搬家箱'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In zh, this message translates to:
  /// **'用于快速登记纸箱、离线搜索物品并追踪搬运状态。全部功能免费，无订阅、试用倒计时或付费墙。'**
  String get aboutBody;

  /// No description provided for @platformSupport.
  ///
  /// In zh, this message translates to:
  /// **'系统要求'**
  String get platformSupport;

  /// No description provided for @platformSupportBody.
  ///
  /// In zh, this message translates to:
  /// **'iOS 15 或更高版本；Android 14 或更高版本。'**
  String get platformSupportBody;

  /// No description provided for @noArchived.
  ///
  /// In zh, this message translates to:
  /// **'没有已归档项目'**
  String get noArchived;

  /// No description provided for @voiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'语音登记'**
  String get voiceTitle;

  /// No description provided for @voiceHint.
  ///
  /// In zh, this message translates to:
  /// **'说出箱内物品、目的房间和注意事项。转写内容可在保存前修改。'**
  String get voiceHint;

  /// No description provided for @startListening.
  ///
  /// In zh, this message translates to:
  /// **'开始录音'**
  String get startListening;

  /// No description provided for @stopListening.
  ///
  /// In zh, this message translates to:
  /// **'停止录音'**
  String get stopListening;

  /// No description provided for @speechUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'语音识别暂不可用'**
  String get speechUnavailable;

  /// No description provided for @speechUnavailableHint.
  ///
  /// In zh, this message translates to:
  /// **'设备、语言或权限可能不支持当前识别。可以立即切换为手动文字登记，不影响其他功能。'**
  String get speechUnavailableHint;

  /// No description provided for @switchManual.
  ///
  /// In zh, this message translates to:
  /// **'改用手动登记'**
  String get switchManual;

  /// No description provided for @transcript.
  ///
  /// In zh, this message translates to:
  /// **'语音转写'**
  String get transcript;

  /// No description provided for @createFromVoice.
  ///
  /// In zh, this message translates to:
  /// **'创建箱子记录'**
  String get createFromVoice;

  /// No description provided for @voiceEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请先录入或手动输入备注'**
  String get voiceEmpty;

  /// No description provided for @permissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'权限未授予，可改用不需要该权限的登记方式。'**
  String get permissionDenied;

  /// No description provided for @photoFailed.
  ///
  /// In zh, this message translates to:
  /// **'照片处理失败，未创建对应记录。'**
  String get photoFailed;

  /// No description provided for @dataError.
  ///
  /// In zh, this message translates to:
  /// **'本地数据读取失败'**
  String get dataError;

  /// No description provided for @editProject.
  ///
  /// In zh, this message translates to:
  /// **'编辑项目'**
  String get editProject;

  /// No description provided for @projectDashboard.
  ///
  /// In zh, this message translates to:
  /// **'项目总览'**
  String get projectDashboard;

  /// No description provided for @boxes.
  ///
  /// In zh, this message translates to:
  /// **'箱子'**
  String get boxes;

  /// No description provided for @viewPending.
  ///
  /// In zh, this message translates to:
  /// **'查看待标记'**
  String get viewPending;

  /// No description provided for @noPending.
  ///
  /// In zh, this message translates to:
  /// **'所有箱子均已确认实体标记'**
  String get noPending;

  /// No description provided for @markConfirmed.
  ///
  /// In zh, this message translates to:
  /// **'确认实体标记'**
  String get markConfirmed;

  /// No description provided for @labelExported.
  ///
  /// In zh, this message translates to:
  /// **'标签已导出'**
  String get labelExported;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @shareCsv.
  ///
  /// In zh, this message translates to:
  /// **'分享 CSV'**
  String get shareCsv;

  /// No description provided for @shareBackup.
  ///
  /// In zh, this message translates to:
  /// **'分享备份'**
  String get shareBackup;

  /// No description provided for @createdAt.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get createdAt;

  /// No description provided for @searchAllHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索全部项目中的箱子'**
  String get searchAllHint;

  /// No description provided for @projectArchived.
  ///
  /// In zh, this message translates to:
  /// **'项目已归档'**
  String get projectArchived;

  /// No description provided for @projectRestored.
  ///
  /// In zh, this message translates to:
  /// **'项目已恢复'**
  String get projectRestored;

  /// No description provided for @projectDeleted.
  ///
  /// In zh, this message translates to:
  /// **'项目已删除'**
  String get projectDeleted;

  /// No description provided for @boxDeleted.
  ///
  /// In zh, this message translates to:
  /// **'箱子记录已删除'**
  String get boxDeleted;

  /// No description provided for @selectMarkMethod.
  ///
  /// In zh, this message translates to:
  /// **'选择已完成的实体标记方式'**
  String get selectMarkMethod;

  /// No description provided for @statusUpdated.
  ///
  /// In zh, this message translates to:
  /// **'状态已更新'**
  String get statusUpdated;

  /// No description provided for @camera.
  ///
  /// In zh, this message translates to:
  /// **'相机'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In zh, this message translates to:
  /// **'照片选择器'**
  String get gallery;

  /// No description provided for @removePhoto.
  ///
  /// In zh, this message translates to:
  /// **'移除照片'**
  String get removePhoto;

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败，请稍后重试'**
  String get exportFailed;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @print.
  ///
  /// In zh, this message translates to:
  /// **'打印'**
  String get print;

  /// No description provided for @allLabels.
  ///
  /// In zh, this message translates to:
  /// **'全部标签'**
  String get allLabels;

  /// No description provided for @unknownProject.
  ///
  /// In zh, this message translates to:
  /// **'未知项目'**
  String get unknownProject;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
