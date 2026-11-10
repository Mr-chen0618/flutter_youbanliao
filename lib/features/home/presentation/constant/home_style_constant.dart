import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/images/app_image.dart';
import '../../../../shared/widgets/text/app_text.dart';
import 'home_assets_constant.dart';

const homeInk = Color(0xFF333333);
const homeMuted = Color(0xFF999999);
const homeYellow = Color(0xFFFFD357);

Widget homeText(
  String text,
  double size, {
  Color color = homeInk,
  FontWeight weight = FontWeight.w400,
  int lines = 1,
  double? lineHeight,
}) => AppText(
  text,
  fontSize: size.sp,
  color: color,
  fontWeight: weight,
  maxLines: lines,
  overflow: TextOverflow.ellipsis,
  lineHeight: lineHeight,
);

Widget homeAsset(String name, double size) =>
    AppImage(src: name, width: size.r, height: size.r, fit: BoxFit.contain);

Widget homeCategoryIcon(String id, double size) {
  final asset = HomeAssets.categoryIcons[id];
  return asset == null
      ? SizedBox.square(dimension: size.r)
      : homeAsset(asset, size);
}
