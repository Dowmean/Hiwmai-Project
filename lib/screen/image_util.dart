// lib/image_util.dart

import 'dart:io';
import 'package:image/image.dart' as img;  // Importing image library for resizing
import 'package:image_picker/image_picker.dart';

Future<File?> pickAndResizeImage() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image == null) return null;

  // Load the image from the file
  final File imageFile = File(image.path);
  final img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

  // Resize the image to a smaller size (e.g., 300x300)
  final img.Image resizedImage = img.copyResize(originalImage!, width: 300, height: 300);

  // Save the resized image back to a file
  final File resizedFile = File(image.path)..writeAsBytesSync(img.encodeJpg(resizedImage));

  return resizedFile;
}
