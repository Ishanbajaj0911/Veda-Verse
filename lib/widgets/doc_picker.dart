import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veda_verse/ai/gemini_client.dart';
import 'package:veda_verse/theme/vv.dart';

/// Lets the user take a photo, choose a photo, or choose a PDF / text file,
/// and returns it as an [Attachment] for Gemini. Shows a short message and
/// returns null for unsupported or too-large files, or if the user cancels.
Future<Attachment?> pickDocument(BuildContext context, {String what = 'report'}) async {
  void toast(String m) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Vv.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: Vv.green),
            title: Text('Take a photo of the $what', style: Vv.sans(15, weight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Vv.green),
            title: Text('Choose a photo', style: Vv.sans(15, weight: FontWeight.w700)),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Vv.green),
            title: Text('Choose a PDF or file', style: Vv.sans(15, weight: FontWeight.w700)),
            subtitle: Text('PDF, photo or text file, up to 12 MB', style: Vv.sans(12, color: Vv.muted)),
            onTap: () => Navigator.pop(ctx, 'file'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null) return null;
  try {
    Attachment a;
    if (choice == 'file') {
      final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: Attachment.supported.keys.toList());
      if (f == null) return null;
      final mime = Attachment.mimeFor(f.name);
      if (mime == null) {
        toast('I can read PDFs, photos and text files. Please share it in one of those.');
        return null;
      }
      final size = await f.length();
      if (size != null && size > Attachment.maxBytes) {
        toast('That file is too large. Please share one under 12 MB.');
        return null;
      }
      a = Attachment(f.name, mime, await f.readAsBytes());
    } else {
      final x = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2000,
      );
      if (x == null) return null;
      a = Attachment(x.name, Attachment.mimeFor(x.name) ?? 'image/jpeg', await x.readAsBytes());
    }
    if (a.bytes.length > Attachment.maxBytes) {
      toast('That file is too large. Please share one under 12 MB.');
      return null;
    }
    return a;
  } catch (e) {
    debugPrint('pickDocument: $e');
    toast('Couldn’t open that file. Please try again.');
    return null;
  }
}
