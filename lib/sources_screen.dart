import 'package:flutter/material.dart';

import 'data.dart';
import 'theme.dart';
import 'version.dart';

class SourcesScreen extends StatelessWidget {
  final AppData data;

  const SourcesScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.palette.primaryDark,
        foregroundColor: const Color(0xFFFFF4DF),
        title: Text(
          'ምንጪታት · Sources & Credits',
          style: AppTheme.geezSans(
            size: 17,
            w: FontWeight.w700,
            color: const Color(0xFFFFF4DF),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EparchyHeader(data: data),
                  const SizedBox(height: 16),
                  const _SourceCard(
                    title: 'አውኒ መሀድዅንና 2026',
                    subtitle: 'Prayer and catechism book · 38 pages',
                    description:
                        'Source for the foundational prayers, Creed and acts, catechism, Confession and Communion, Rosary and Marian prayers, and blessings at meals.',
                  ),
                  const SizedBox(height: 12),
                  const _SourceCard(
                    title: 'ፊዅሰን መስቀሉ',
                    subtitle: 'Way of the Cross and Divine Mercy · 2025',
                    description:
                        'Source for the complete daily-prayer sequence, preparation, fourteen stations, conclusion, fifteen illustrations, and the complete Divine Mercy devotion.',
                  ),
                  const SizedBox(height: 12),
                  const _SourceCard(
                    title: 'ይና ገና ማርያም ጊመት ሰላምሪ',
                    subtitle: 'Mary, Queen of Peace · supplied prayer sheet',
                    description:
                        'Source for the seven-stanza Marian prayer. The English title is an editorial aid pending final Blin review.',
                  ),
                  const SizedBox(height: 12),
                  const _SourceCard(
                    title: 'Supporting material',
                    subtitle: 'Our Father.docx and the supplied Jesus image',
                    description:
                        'The Word document confirms the standard-prayer wording. The supplied Jesus image is used directly in Divine Mercy.',
                  ),
                  const SizedBox(height: 18),
                  const _AuthorizationCard(),
                  const SizedBox(height: 18),
                  _CreditsCard(data: data),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EparchyHeader extends StatelessWidget {
  final AppData data;

  const _EparchyHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.palette.primary, context.palette.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.goldDecorative),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCF6),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/source_2026/provenance/eparchy_emblem.jpg',
              fit: BoxFit.contain,
              semanticLabel: 'Catholic Eparchy of Keren emblem',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTheme.geezSerif(
              size: 27,
              w: FontWeight.w700,
              color: const Color(0xFFFFF4DF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.source,
            textAlign: TextAlign.center,
            style: AppTheme.geezSans(
              size: 15,
              w: FontWeight.w600,
              color: const Color(0xFFE9D9BA),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;

  const _SourceCard({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.geezSerif(
              size: 19,
              w: FontWeight.w700,
              color: context.palette.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTheme.geezSans(
              size: 13.5,
              w: FontWeight.w600,
              color: context.palette.goldText,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            description,
            style: AppTheme.geezSans(
              size: 15,
              w: FontWeight.w400,
              color: context.palette.inkMuted,
            ).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _AuthorizationCard extends StatelessWidget {
  const _AuthorizationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.goldDecorative),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authorization and source identity',
            style: AppTheme.geezSans(
              size: 17,
              w: FontWeight.w700,
              color: context.palette.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The following mark is reproduced from the introductory authorization page of the supplied 2026 book. It is shown here as source context, not as decoration inside a prayer.',
            style: AppTheme.geezSans(
              size: 14.5,
              w: FontWeight.w400,
              color: context.palette.inkMuted,
            ).copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/source_2026/provenance/authorization_signature.jpg',
              height: 90,
              fit: BoxFit.contain,
              semanticLabel:
                  'Authorization signature and Catholic Eparchy of Keren emblem from the supplied source book',
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  final AppData data;

  const _CreditsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credits and version',
            style: AppTheme.geezSans(
              size: 17,
              w: FontWeight.w700,
              color: context.palette.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'App version $appVersion ($buildNumber)\n'
            'Content version $contentVersion\n'
            '${data.items.where((item) => item.kind == 'prayer').length} prayer sections · '
            '${data.catechism.length} catechism topics · ${data.hymns.length} hymns\n\n'
            'Prayer texts and source images: Catholic Eparchy of Keren and the supplied source materials.\n\n'
            'Fonts: Noto Sans Ethiopic, Noto Serif Ethiopic, and Cormorant Garamond, distributed under the SIL Open Font License.',
            style: AppTheme.geezSans(
              size: 14.5,
              w: FontWeight.w400,
              color: context.palette.inkMuted,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
