import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;
    FocusScope.of(context).unfocus();

    final success =
        await ref.read(apiKeyProvider.notifier).validateAndSave(key);

    if (!mounted) return;
    if (success) {
      _keyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key verified and saved')),
      );
    } else {
      final error = ref.read(apiKeyProvider).errorMessage ?? 'Invalid key';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyState = ref.watch(apiKeyProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionLabel('AI Provider'),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'OpenRouter',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15.5),
                      ),
                    ),
                    _StatusChip(status: apiKeyState.status),
                  ],
                ),
                const SizedBox(height: 14),
                if (apiKeyState.status == ApiKeyStatus.valid &&
                    apiKeyState.maskedKey != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.key_rounded,
                            size: 16, color: Theme.of(context).hintColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            apiKeyState.maskedKey!,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (apiKeyState.remainingCredits != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Remaining credits: \$${apiKeyState.remainingCredits!.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 12.5, color: Theme.of(context).hintColor),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _keyController.clear();
                            });
                            ref.read(apiKeyProvider.notifier).clearKey();
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: const Text('Remove key'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'sk-or-v1-…',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: apiKeyState.status == ApiKeyStatus.validating
                          ? null
                          : _handleSaveKey,
                      child: apiKeyState.status == ApiKeyStatus.validating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify & Save'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('https://openrouter.ai/keys'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Get a free API key at openrouter.ai',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('Appearance'),
          _SettingsCard(
            child: Column(
              children: [
                _ThemeOption(
                  label: 'System default',
                  icon: Icons.brightness_auto_rounded,
                  selected: themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system),
                ),
                const Divider(height: 20),
                _ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  selected: themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 20),
                _ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('Model Defaults'),
          _SettingsCard(
            child: Consumer(
              builder: (context, ref, _) {
                final temperature = ref.watch(temperatureProvider);
                final maxTokens = ref.watch(maxTokensProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Temperature',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(temperature.toStringAsFixed(1),
                            style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: temperature,
                      min: 0,
                      max: 2,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          ref.read(temperatureProvider.notifier).state = v,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Max tokens',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('$maxTokens',
                            style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: maxTokens.toDouble(),
                      min: 256,
                      max: 8192,
                      divisions: 31,
                      activeColor: AppColors.primary,
                      onChanged: (v) => ref
                          .read(maxTokensProvider.notifier)
                          .state = v.round(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('About'),
          _SettingsCard(
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('AI Hub'),
                    Spacer(),
                    Text('v0.1.0 (Phase 1)'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: selected ? AppColors.primary : Theme.of(context).hintColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ApiKeyStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ApiKeyStatus.valid => (AppColors.success, 'Connected'),
      ApiKeyStatus.invalid => (AppColors.error, 'Invalid'),
      ApiKeyStatus.validating => (AppColors.warning, 'Checking…'),
      ApiKeyStatus.notSet => (Colors.grey, 'Not set'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
