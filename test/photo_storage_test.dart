import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moving_box/services/photo_storage.dart';

void main() {
  test('a one-photo request uses the single-image picker', () async {
    final picker = _RecordingImagePicker();
    final storage = PhotoStorage(picker: picker);

    final selected = await storage.choosePhotos(limit: 1);

    expect(selected, hasLength(1));
    expect(picker.singleImageCalls, 1);
    expect(picker.multiImageCalls, 0);
  });

  test('multi-photo requests still use the multi-image picker', () async {
    final picker = _RecordingImagePicker();
    final storage = PhotoStorage(picker: picker);

    final selected = await storage.choosePhotos(limit: 3);

    expect(selected, hasLength(2));
    expect(picker.singleImageCalls, 0);
    expect(picker.multiImageCalls, 1);
  });
}

class _RecordingImagePicker extends ImagePicker {
  int singleImageCalls = 0;
  int multiImageCalls = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    singleImageCalls += 1;
    expect(source, ImageSource.gallery);
    expect(requestFullMetadata, isFalse);
    return XFile.fromData(Uint8List.fromList([1]), path: 'single.jpg');
  }

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    multiImageCalls += 1;
    expect(limit, 3);
    expect(requestFullMetadata, isFalse);
    return [
      XFile.fromData(Uint8List.fromList([1]), path: 'first.jpg'),
      XFile.fromData(Uint8List.fromList([2]), path: 'second.jpg'),
    ];
  }
}
