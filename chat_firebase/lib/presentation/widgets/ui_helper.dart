import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatappui/core/constants/app_colors.dart';
import 'package:chatappui/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UiHelper {
  static Widget customText({
    required String text,
    required double fontSize,
    required BuildContext context,
    String? fontFamily,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
  }) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily ?? 'regular',
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? theme.colorScheme.onSurface,
      ),
    );
  }

  static Widget customButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return SizedBox(
      height: 50,
      width: 350,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : customButtonLabel(label),
      ),
    );
  }

  static Widget customButtonLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontFamily: 'bold',
      ),
    );
  }

  static Widget customTextField({
    required TextEditingController controller,
    required String hintText,
    required BuildContext context,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      width: 360,
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        maxLines: maxLines,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontFamily: 'regular',
        ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            prefixIcon,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          errorText: errorText,
        ),
      ),
    );
  }

  static Widget avatar({
    required String name,
    String? photoUrl,
    double radius = 24,
    Color? bgColor,
  }) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                _initialsAvatar(name: name, radius: radius, bgColor: bgColor),
            errorWidget: (_, __, ___) =>
                _initialsAvatar(name: name, radius: radius, bgColor: bgColor),
          ),
        ),
      );
    }

    return _initialsAvatar(name: name, radius: radius, bgColor: bgColor);
  }

  static Widget _initialsAvatar({
    required String name,
    double radius = 24,
    Color? bgColor,
  }) {
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((word) => word.isNotEmpty ? word[0] : '')
            .take(2)
            .join()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor ?? AppColors.buttonLight,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'bold',
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget darkModeToggle(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return IconButton(
      tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => context.read<ThemeProvider>().toggleDarkMode(),
    );
  }

  static Widget sectionDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerTheme.color,
    );
  }

  static Widget loadingPlaceholder({
    double height = 180,
    double width = double.infinity,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(strokeWidth: 2.2),
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
      ),
    );
  }

  static Widget assetImage(String filename) =>
      Image.asset('assets/images/$filename');
}
