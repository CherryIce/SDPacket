import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoStorage {
  PhotoStorage({ImagePicker? picker, Uuid? uuid})
    : picker = picker ?? ImagePicker(),
      _uuid = uuid ?? const Uuid();

  final ImagePicker picker;
  final Uuid _uuid;

  Future<List<XFile>> choosePhotos({int limit = 30}) async {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be at least 1');
    }
    if (limit == 1) {
      final selected = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 2400,
        requestFullMetadata: false,
      );
      return selected == null ? const [] : [selected];
    }
    final selected = await picker.pickMultiImage(
      limit: limit,
      imageQuality: 86,
      maxWidth: 2400,
      requestFullMetadata: false,
    );
    return selected.take(limit).toList(growable: false);
  }

  Future<XFile?> takePhoto() => picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 86,
    maxWidth: 2400,
  );

  Future<List<XFile>> retrieveLostPhotos() async {
    final response = await picker.retrieveLostData();
    if (response.isEmpty) return const [];
    return response.files ?? const [];
  }

  Future<String> persist(XFile source) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/moving_box/photos');
    await directory.create(recursive: true);
    final extension = _safeExtension(source.path);
    final target = File('${directory.path}/${_uuid.v4()}$extension');
    try {
      await source.saveTo(target.path);
      return target.path;
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }

  Future<void> deleteIfManaged(String path) async {
    final support = await getApplicationSupportDirectory();
    final managedRoot = '${support.path}/moving_box/photos/';
    if (!path.startsWith(managedRoot)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

String _safeExtension(String path) {
  final slash = path.lastIndexOf('/');
  final dot = path.lastIndexOf('.');
  if (dot <= slash || path.length - dot > 6) return '.jpg';
  final candidate = path.substring(dot).toLowerCase();
  return RegExp(r'^\.[a-z0-9]+$').hasMatch(candidate) ? candidate : '.jpg';
}
