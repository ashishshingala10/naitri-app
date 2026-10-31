import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api.dart';
import '../theme.dart';

/// Two mandatory captures at handset handover:
///   face        — plain customer selfie
///   with_device — customer holding the financed handset
class SelfieCaptureScreen extends StatefulWidget {
  final int? loanId;
  const SelfieCaptureScreen({super.key, this.loanId});
  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  final _picker = ImagePicker();
  File? _face;
  File? _withDevice;
  bool _submitting = false;

  Future<void> _shoot(bool face) async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,     // compress → faster upload
      maxWidth: 1080,
    );
    if (x == null) return;
    setState(() {
      if (face) {
        _face = File(x.path);
      } else {
        _withDevice = File(x.path);
      }
    });
  }

  Future<void> _submit() async {
    if (_face == null || _withDevice == null) return;
    setState(() => _submitting = true);
    try {
      await Api.i.uploadSelfie(file: _face!, kind: 'face', loanId: widget.loanId);
      await Api.i.uploadSelfie(file: _withDevice!, kind: 'with_device', loanId: widget.loanId);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Brand.ok, content: Text('Photos submitted. Thank you.')),
      );
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Brand.red, content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _face != null && _withDevice != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify handover')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Two quick photos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('This confirms the handset reached you. Make sure your face is clear and well lit.',
                style: TextStyle(color: Brand.inkSoft, fontSize: 14)),
            const SizedBox(height: 22),
            _tile(
              label: 'Your selfie',
              hint: 'Face only, looking at the camera',
              file: _face,
              onTap: () => _shoot(true),
            ),
            const SizedBox(height: 16),
            _tile(
              label: 'Selfie with the handset',
              hint: 'Hold the new phone next to your face',
              file: _withDevice,
              onTap: () => _shoot(false),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: ready && !_submitting ? _submit : null,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit photos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({required String label, required String hint, required File? file, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: file != null ? Brand.ok : Brand.line, width: file != null ? 1.5 : 1),
          image: file != null ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
        ),
        child: file != null
            ? Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircleAvatar(radius: 16, backgroundColor: Brand.ok, child: const Icon(Icons.check, color: Colors.white, size: 18)),
                ),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.photo_camera_outlined, size: 34, color: Brand.red),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(hint, style: const TextStyle(color: Brand.inkSoft, fontSize: 12.5)),
                const SizedBox(height: 8),
                const Text('Tap to open camera', style: TextStyle(color: Brand.red, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }
}
