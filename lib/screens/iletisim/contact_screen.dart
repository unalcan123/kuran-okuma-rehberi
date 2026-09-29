import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';

/// Where the users' messages go.
const String kContactEmail = 'fluttercanpolat@gmail.com';

/// Konu seçenekleri.
const List<String> kContactTopics = [
  'Öneri',
  'Hata bildirimi',
  'Teşekkür',
  'Diğer',
];

/// The e-mail the "E-posta ile Gönder" button opens: to [kContactEmail],
/// with the topic as subject and the name + message as body. Pure (tests).
Uri contactMailUri({
  required String topic,
  String name = '',
  String message = '',
}) {
  final body = StringBuffer();
  if (message.trim().isNotEmpty) body.writeln(message.trim());
  if (name.trim().isNotEmpty) {
    body
      ..writeln()
      ..writeln('— ${name.trim()}');
  }
  return Uri(
    scheme: 'mailto',
    path: kContactEmail,
    // `query` (not queryParameters): mail apps want %20, not "+".
    query: _encodeQuery({
      'subject': "Kur'an Okuma Rehberi – $topic",
      if (body.isNotEmpty) 'body': body.toString(),
    }),
  );
}

String _encodeQuery(Map<String, String> params) => params.entries
    .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
    .join('&');

/// Home screen entry: "Bize Ulaşın" under the four cards.
class ContactEntryCard extends StatelessWidget {
  const ContactEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('home-contact'),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContactScreen()),
            ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const _EnvelopeBadge(size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bize Ulaşın',
                      style: theme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Görüşünü, önerini yaz; resim de ekleyebilirsin.',
                      style: theme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Bize Ulaşın": a friendly picture, what to write about, the address
/// (copyable), and a short form that opens the user's e-mail app with the
/// message ready — pictures / screenshots are attached there (📎).
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, this.launcher});

  /// Opens the e-mail (replaced in tests).
  final Future<bool> Function(Uri uri)? launcher;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _name = TextEditingController();
  final _message = TextEditingController();
  String _topic = kContactTopics.first;

  @override
  void dispose() {
    _name.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _copyAddress() async {
    await Clipboard.setData(const ClipboardData(text: kContactEmail));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-posta adresi kopyalandı')),
    );
  }

  Future<void> _send() async {
    final uri = contactMailUri(
      topic: _topic,
      name: _name.text,
      message: _message.text,
    );
    var opened = false;
    try {
      opened = await (widget.launcher ?? launchUrl)(uri);
    } catch (_) {
      opened = false;
    }
    if (opened || !mounted) return;
    // No e-mail app: the address goes to the clipboard instead.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'E-posta uygulaması açılamadı. Adres kopyalandı: $kContactEmail',
        ),
      ),
    );
    await Clipboard.setData(const ClipboardData(text: kContactEmail));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Bize Ulaşın')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 572 / 300,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/reading/reading_scene.webp',
                          key: const ValueKey('contact-picture'),
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.2),
                          excludeFromSemantics: true,
                          errorBuilder:
                              (_, _, _) => const ColoredBox(
                                color: AppColors.skyBlueSoft,
                              ),
                        ),
                        const Positioned(
                          right: 14,
                          bottom: 14,
                          child: _EnvelopeBadge(size: 72),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Bize yazın!',
                  style: theme.headlineSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulamayla ilgili görüşünü, önerini ya da bulduğun bir '
                  'hatayı bize e-postayla gönderebilirsin. Mesajına resim veya '
                  'ekran görüntüsü de ekleyebilirsin.',
                  style: theme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _AddressCard(onCopy: _copyAddress),
                const SizedBox(height: 20),
                Text(
                  'Konu',
                  style: theme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in kContactTopics)
                      ChoiceChip(
                        key: ValueKey('contact-topic-$topic'),
                        label: Text(topic),
                        selected: _topic == topic,
                        showCheckmark: false,
                        selectedColor: AppColors.turquoiseSoft,
                        onSelected: (_) => setState(() => _topic = topic),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('contact-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Adın (isteğe bağlı)',
                    prefixIcon: Icon(Icons.person_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('contact-message'),
                  controller: _message,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Mesajın',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Resim eklemek için açılan e-posta uygulamasında '
                          'ataç simgesine dokun.',
                          style: theme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    key: const ValueKey('contact-send'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                      shape: const StadiumBorder(),
                      textStyle: theme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('E-posta ile Gönder'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        const Icon(Icons.alternate_email_rounded, color: AppColors.turquoise),
        const SizedBox(width: 10),
        const Expanded(
          child: SelectableText(
            kContactEmail,
            key: ValueKey('contact-address'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('contact-copy'),
          tooltip: 'Adresi kopyala',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded),
        ),
      ],
    ),
  );
}

/// A round envelope badge (drawn with an icon, no picture file).
class _EnvelopeBadge extends StatelessWidget {
  const _EnvelopeBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFD27A), Color(0xFFFF9FB2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(
      Icons.mark_email_unread_rounded,
      color: Colors.white,
      size: size * 0.52,
    ),
  );
}
