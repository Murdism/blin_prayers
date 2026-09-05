import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';
import 'widgets.dart';

class QuizScreen extends StatefulWidget {
  final AppData data;
  const QuizScreen({super.key, required this.data});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizPair>? pool;
  int idx = 0;
  bool revealed = false;

  void _start(List<QuizPair> source) {
    final p = List<QuizPair>.from(source)..shuffle(Random());
    setState(() {
      pool = p;
      idx = 0;
      revealed = false;
    });
  }

  void _exit() => setState(() {
        pool = null;
        idx = 0;
        revealed = false;
      });

  @override
  Widget build(BuildContext context) {
    return pool == null ? _menu() : _active();
  }

  Widget _menu() {
    final topics = widget.data.catechism.where((t) => t.qa.isNotEmpty).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        CollectionHero(
          eyebrow: 'Learn by remembering',
          title: 'ፈተና ምህሮ',
          subtitle: 'Catechism Quiz',
          description:
              'Read each question, recall the answer, and reveal it when you are ready.',
          icon: Icons.psychology_alt_rounded,
          badge: '${widget.data.quiz.length} questions',
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            color: context.palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.outline, width: 1.5),
          ),
          child: Column(children: [
            Text('${widget.data.quiz.length} questions',
                style: AppTheme.latin(size: 15)),
            const SizedBox(height: 8),
            Text('ፈተና',
                textAlign: TextAlign.center,
                style: AppTheme.geezSerif(size: 21, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'Test what you have learned. Read each question, '
                'recall the answer, then reveal it.',
                textAlign: TextAlign.center,
                style: AppTheme.latin(size: 15)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: context.palette.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => _start(widget.data.quiz),
                child: Text('ናውክ· All topics',
                    style: AppTheme.geezSerif(
                        size: 16,
                        w: FontWeight.w700,
                        color: const Color(0xFFF7ECD6))),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            for (final t in topics)
              TileCard(
                kicker: '${t.qa.length} Q',
                title: t.title,
                icon: Icons.quiz_outlined,
                onTap: () => _start(
                    t.qa.map((p) => QuizPair(t.title, p.q, p.a)).toList()),
              ),
          ],
        ),
      ],
    );
  }

  Widget _active() {
    final p = pool![idx];
    final last = idx + 1 >= pool!.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        _viewTitle('ፈተና ምህሮ', 'Catechism Quiz'),
        const Ornament(glyph: '✝'),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          decoration: BoxDecoration(
            color: context.palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.outline, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1F3C2614),
                  blurRadius: 18,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Column(children: [
            Text('${idx + 1} / ${pool!.length}',
                style: AppTheme.latin(size: 15)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (idx + 1) / pool!.length,
                minHeight: 7,
                backgroundColor: context.palette.surfaceMuted,
                color: context.palette.primary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.palette.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(p.topic,
                  style: AppTheme.geezSerif(
                      size: 13,
                      w: FontWeight.w600,
                      color: context.palette.primary)),
            ),
            const SizedBox(height: 16),
            Text(p.q,
                textAlign: TextAlign.center,
                style: AppTheme.geezSerif(size: 21, w: FontWeight.w700)),
            const SizedBox(height: 20),
            if (revealed)
              AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: context.palette.goldDecorative,
                        width: 1.5,
                        style: BorderStyle.solid),
                  ),
                  child: SelectableText(p.a,
                      style: AppTheme.geezSerif(
                              size: 17, color: context.palette.ink)
                          .copyWith(height: 1.8)),
                ),
              ),
            const SizedBox(height: 22),
            Row(children: [
              if (!revealed)
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: context.palette.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => setState(() => revealed = true),
                    child: Text('ቀልዒ · Reveal',
                        style: AppTheme.geezSerif(
                            size: 16,
                            w: FontWeight.w700,
                            color: const Color(0xFFF7ECD6))),
                  ),
                )
              else
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: context.palette.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      if (last) {
                        _exit();
                      } else {
                        setState(() {
                          idx++;
                          revealed = false;
                        });
                      }
                    },
                    child: Text(last ? 'ተመሙኽ · Finish' : 'ኰዶ → · Next',
                        style: AppTheme.geezSerif(
                            size: 16,
                            w: FontWeight.w700,
                            color: const Color(0xFFF7ECD6))),
                  ),
                ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: context.palette.primary,
                    side:
                        BorderSide(color: context.palette.outline, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 18)),
                onPressed: _exit,
                child: Text('ደምቢራ',
                    style: AppTheme.geezSerif(
                        size: 16,
                        w: FontWeight.w700,
                        color: context.palette.primary)),
              ),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _viewTitle(String t, String en) => Padding(
        padding: const EdgeInsets.only(top: 10, left: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(t,
              style: AppTheme.geezSerif(
                  size: 22,
                  w: FontWeight.w700,
                  color: context.palette.primary)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(en, style: AppTheme.latin(size: 15)),
          ),
        ]),
      );
}
