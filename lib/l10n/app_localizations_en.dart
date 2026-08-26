// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Moving Box';

  @override
  String get loading => 'Loading local data…';

  @override
  String get retry => 'Retry';

  @override
  String get projects => 'Moving projects';

  @override
  String get newProject => 'New project';

  @override
  String get globalSearch => 'Global search';

  @override
  String get archivedProjects => 'Archived projects';

  @override
  String get settings => 'Settings';

  @override
  String get noProjects => 'No moving projects yet';

  @override
  String get noProjectsHint => 'Create a project to start registering boxes.';

  @override
  String get sampleProjectName => 'Sample move';

  @override
  String get sampleOrigin => 'Old home';

  @override
  String get sampleDestination => 'New home';

  @override
  String get sampleMemo => 'Coffee maker, cups and filters';

  @override
  String get projectName => 'Project name';

  @override
  String get origin => 'Origin (optional)';

  @override
  String get destination => 'Destination (optional)';

  @override
  String get boxPrefix => 'Box prefix';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get archive => 'Archive';

  @override
  String get restore => 'Restore';

  @override
  String get delete => 'Delete';

  @override
  String get deleteProjectConfirm =>
      'Deleting this project also deletes its box records. Old labels may remain on physical boxes. Continue?';

  @override
  String get deleteBoxConfirm =>
      'This box number will not be reused. Old labels may remain on the physical box. Continue?';

  @override
  String boxCount(int count) {
    return '$count boxes';
  }

  @override
  String get quickEntry => 'Quick entry';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get choosePhotos => 'Choose photos';

  @override
  String get voiceEntry => 'Voice entry';

  @override
  String get manualEntry => 'Manual entry';

  @override
  String get photoLimit => 'Choose up to 30 photos per batch.';

  @override
  String batchCreated(int count, Object from, Object to) {
    return 'Created $count box records: $from to $to';
  }

  @override
  String get physicalMarkTitle => 'Mark the physical box';

  @override
  String physicalMarkMessage(Object code) {
    return 'Digital record $code was created. Write the code on the box, use a sticky note, or attach a QR label.';
  }

  @override
  String physicalMarkBatchMessage(int count) {
    return 'Created $count digital records. Match each photo and code to a physical box to avoid mix-ups.';
  }

  @override
  String get qrLabel => 'QR label attached';

  @override
  String get handwritten => 'Code handwritten';

  @override
  String get stickyNote => 'Sticky note attached';

  @override
  String get other => 'Other method';

  @override
  String get later => 'Do later';

  @override
  String get pendingPhysicalMark => 'Needs physical mark';

  @override
  String get marked => 'Mark confirmed';

  @override
  String get progress => 'Move progress';

  @override
  String get total => 'Total';

  @override
  String get packed => 'Packed';

  @override
  String get loaded => 'Loaded';

  @override
  String get arrived => 'Arrived';

  @override
  String get unpacked => 'Unpacked';

  @override
  String get draft => 'Draft';

  @override
  String get suspectedMissing => 'Possibly missing';

  @override
  String get damagedBox => 'Box damaged';

  @override
  String get damagedContents => 'Contents damaged';

  @override
  String get priority => 'Unpack first';

  @override
  String get normal => 'Normal';

  @override
  String get searchBoxes => 'Search code, notes, items, room or tags';

  @override
  String get noResults => 'No matching results';

  @override
  String get boxCode => 'Box code';

  @override
  String get boxTitle => 'Title (optional)';

  @override
  String get destinationRoom => 'Destination room (optional)';

  @override
  String get currentLocation => 'Current location (optional)';

  @override
  String get memo => 'Notes (optional)';

  @override
  String get tags => 'Tags';

  @override
  String get tagsHint => 'Separate with commas, e.g. Fragile, Keep dry';

  @override
  String get items => 'Structured items';

  @override
  String get itemsHint => 'Separate item names with commas (optional)';

  @override
  String get duplicateCode => 'This code is already used in the project';

  @override
  String get boxSaved => 'Box record saved';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get qrAndPrint => 'QR and printing';

  @override
  String get scan => 'Scan box label';

  @override
  String get unsupportedQr =>
      'This is not a supported box label. Go back and search by code instead.';

  @override
  String get boxNotFound =>
      'The label is valid, but its box record is not on this device.';

  @override
  String get moveStatus => 'Move status';

  @override
  String get issues => 'Issue flags';

  @override
  String get physicalMark => 'Physical mark';

  @override
  String get exportSinglePdf => 'Share single PDF';

  @override
  String get exportPng => 'Share high-resolution PNG';

  @override
  String get printLabel => 'System print';

  @override
  String get exportA4Pdf => 'Share all A4 labels';

  @override
  String get labelExportedNotice =>
      'The label was exported, but you still need to confirm it was attached or the code was written on the physical box.';

  @override
  String noPrinterHint(Object code) {
    return 'No printer is required. Write $code clearly on the box or on a sticky note and attach it.';
  }

  @override
  String get exportCsv => 'Export project CSV';

  @override
  String get backup => 'Share local backup';

  @override
  String get restoreBackup => 'Restore from file';

  @override
  String get restoreWarning =>
      'The backup is fully validated first. A valid backup replaces current local data; invalid data never overwrites existing records.';

  @override
  String get restoreSuccess => 'Backup restored';

  @override
  String get invalidBackup =>
      'Invalid or unsupported backup. Existing data was not changed.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'Projects, boxes, notes and photos stay on this device by default. Core features do not require accounts, ad SDKs or third-party AI. QR codes contain only a format version, project ID, box ID and readable code—not addresses, photos or item lists. Camera, photos, microphone and speech permissions are requested only when you use those features.';

  @override
  String get about => 'About Moving Box';

  @override
  String get aboutBody =>
      'Quickly register boxes, find items offline and track moving status. Every feature is free, with no subscription, trial countdown or paywall.';

  @override
  String get platformSupport => 'System requirements';

  @override
  String get platformSupportBody => 'iOS 15 or later; Android 14 or later.';

  @override
  String get noArchived => 'No archived projects';

  @override
  String get voiceTitle => 'Voice entry';

  @override
  String get voiceHint =>
      'Say the items, destination room and handling notes. You can edit the transcript before saving.';

  @override
  String get startListening => 'Start listening';

  @override
  String get stopListening => 'Stop listening';

  @override
  String get speechUnavailable => 'Speech recognition unavailable';

  @override
  String get speechUnavailableHint =>
      'Your device, language or permission may not support recognition. Switch to manual text entry without affecting other features.';

  @override
  String get switchManual => 'Use manual entry';

  @override
  String get transcript => 'Transcript';

  @override
  String get createFromVoice => 'Create box record';

  @override
  String get voiceEmpty => 'Record or enter a note first';

  @override
  String get permissionDenied =>
      'Permission was not granted. You can use an entry method that does not need it.';

  @override
  String get photoFailed =>
      'Photo processing failed; no record was created for it.';

  @override
  String get dataError => 'Could not load local data';

  @override
  String get editProject => 'Edit project';

  @override
  String get projectDashboard => 'Project overview';

  @override
  String get boxes => 'Boxes';

  @override
  String get viewPending => 'View pending';

  @override
  String get noPending => 'Every box has a confirmed physical mark';

  @override
  String get markConfirmed => 'Confirm physical mark';

  @override
  String get labelExported => 'Label exported';

  @override
  String get close => 'Close';

  @override
  String get shareCsv => 'Share CSV';

  @override
  String get shareBackup => 'Share backup';

  @override
  String get createdAt => 'Created';

  @override
  String get searchAllHint => 'Search boxes across all projects';

  @override
  String get projectArchived => 'Project archived';

  @override
  String get projectRestored => 'Project restored';

  @override
  String get projectDeleted => 'Project deleted';

  @override
  String get boxDeleted => 'Box record deleted';

  @override
  String get selectMarkMethod => 'Choose the completed physical marking method';

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Photo picker';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get exportFailed => 'Export failed. Try again later.';

  @override
  String get share => 'Share';

  @override
  String get print => 'Print';

  @override
  String get allLabels => 'All labels';

  @override
  String get unknownProject => 'Unknown project';
}
