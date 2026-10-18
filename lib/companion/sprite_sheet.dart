import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'soul_state.dart';

/// Cloud Friend sprite sheet layout (built from the original mascot PNG).
abstract final class CloudFriendSheet {
  static const assetPath = 'assets/companion/cloud_friend_sheet.png';

  static const frameSize = 512.0;
  static const columns = 6;

  /// Frame index in the sheet (row-major).
  static const idle = [0, 1, 2, 3, 4, 5];
  static const blink = [6, 7, 8];
  static const lonely = [9, 10, 11, 12];
  static const happy = [13, 14, 15, 16];
  static const waiting = [17, 18, 19, 20];

  static List<int> loopFor(SoulState state) => switch (state) {
    SoulState.waiting => waiting,
    SoulState.lonely => lonely,
    SoulState.whole => idle,
    SoulState.reunited => happy,
  };

  static Rect frameRect(int index) {
    final col = index % columns;
    final row = index ~/ columns;
    return Rect.fromLTWH(
      col * frameSize,
      row * frameSize,
      frameSize,
      frameSize,
    );
  }
}

class SpriteFramePainter extends CustomPainter {
  SpriteFramePainter({required this.image, required this.frameIndex});

  final ui.Image image;
  final int frameIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final src = CloudFriendSheet.frameRect(frameIndex);
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant SpriteFramePainter oldDelegate) {
    return frameIndex != oldDelegate.frameIndex || image != oldDelegate.image;
  }
}
