import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../shared/widgets/hymn_audio_mark.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/hymn.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive/reading_width_constraint.dart';
import '../../../shared/widgets/app_cards.dart';
import '../../../shared/widgets/keep_awake.dart';
import '../../church_texts/data/book_of_worship_data.dart';
import '../../church_texts/data/church_texts_data.dart';
import '../../church_texts/models/church_text.dart';
import '../../church_texts/screens/church_text_screen.dart';
import '../../church_texts/widgets/church_text_links.dart';
import '../../church_texts/screens/church_texts_screen.dart';
import '../../church_texts/services/church_text_prefs.dart';
import '../../hymn_lists/screens/hymn_list_player_screen.dart';
import '../../hymn_lists/screens/hymn_lists_screen.dart';
import '../../hymn_lists/services/hymn_list_service.dart';
import '../../hymns/repository/hymns_repository.dart';
import '../../liturgy/data/worship_order_data.dart';
import '../../liturgy/models/liturgical_period.dart';
import '../../liturgy/services/church_calendar.dart';
import '../../liturgy/screens/liturgical_period_detail_screen.dart';
import '../../liturgy/services/liturgical_calendar_service.dart';
import '../../liturgy/widgets/season_card.dart';
import '../services/worship_service.dart';

/// "Culte du dimanche": everything used during the service on one screen —
/// the season of the day, the hymns chosen for the service, the order of
/// worship and the prayers said together.
class WorshipScreen extends StatefulWidget {
  const WorshipScreen({super.key});

  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> {
  final _repo = HymnsRepository();
  late final DateTime _day = WorshipService.serviceDay(DateTime.now());
  LiturgicalPeriodInstance? _season;

  /// The Sunday of the Christian year (and the special Sundays) of the service day.
  late final List<ChurchDay> _sundayEntries = ChurchCalendar.daysOn(_day);
  LiturgicalPeriodInstance? _holyDay;

  List<HymnList> _lists = [];
  HymnList? _list;
  List<Hymn> _hymns = [];
  List<ChurchText> _prayers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    try {
      final (season, all) = LiturgicalCalendarService.currentSeason(_day);
      _season = season;
      _holyDay = LiturgicalCalendarService.holyDayOn(_day, all);
    } catch (_) {
      // The season is a help, not a requirement of this screen.
    }
    _load();
  }

  Future<void> _load() async {
    var lists = <HymnList>[];
    HymnList? chosen;
    final hymns = <Hymn>[];
    var pinned = <String>[];
    try {
      lists = await HymnListService.getAll();
      final chosenId = await WorshipService.chosenListId();
      for (final list in lists) {
        if (list.id == chosenId) chosen = list;
      }
      // With a single list there is nothing to choose.
      chosen ??= lists.length == 1 ? lists.first : null;
      if (chosen != null) {
        for (final number in chosen.numbers) {
          final hymn = await _repo.getByNumber(number);
          if (hymn != null) hymns.add(hymn);
        }
      }
      pinned = await ChurchTextPrefs.pinned();
    } catch (_) {
      // Shown as "no list yet": the rest of the screen still works.
    }
    if (!mounted) return;
    setState(() {
      _lists = lists;
      _list = chosen;
      _hymns = hymns;
      // The pinned texts, or the two said most often when none is pinned.
      final texts = [
        for (final id in pinned)
          if (ChurchTextsData.byId(id) != null) ChurchTextsData.byId(id)!,
      ];
      _prayers = texts.isNotEmpty
          ? texts
          : const [ChurchTextsData.lordsPrayer, ChurchTextsData.socialCreed];
      _loading = false;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  Future<void> _chooseList() async {
    if (_lists.isEmpty) {
      await _open(const HymnListsScreen());
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                sheetContext.tr('wo_hymns'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final list in _lists)
              ListTile(
                leading: Icon(
                  list.id == _list?.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(list.name),
                subtitle: Text(sheetContext.trf('wo_n_hymns', {'n': list.numbers.length})),
                onTap: () => Navigator.of(sheetContext).pop(list.id),
              ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(sheetContext.tr('wo_manage')),
              onTap: () => Navigator.of(sheetContext).pop('manage'),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked == 'manage') {
      await _open(const HymnListsScreen());
      return;
    }
    await WorshipService.chooseList(picked);
    if (mounted) _load();
  }

  void _sing(int index) {
    final list = _list;
    if (list == null) return;
    _open(HymnListPlayerScreen(
        listName: list.name, hymns: _hymns, initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lineHeight = context.watch<AppSettings>().lineHeightScale;
    final today = DateTime.now();
    final isToday = _day.year == today.year &&
        _day.month == today.month &&
        _day.day == today.day;
    final season = _holyDay ?? _season;
    final list = _list;

    return KeepAwake(
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('lg_worship'))),
        body: ReadingWidthConstraint(
          maxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Text(
                context.tr(isToday ? 'wo_today' : 'wo_next'),
                style: TextStyle(fontSize: 13.5, color: palette.muted),
              ),
              const SizedBox(height: 2),
              Semantics(
                header: true,
                child: Text(
                  context.trf('wo_date', {
                    'd': _day.day,
                    'm': AppStrings.monthName(_day.month, context.lang),
                    'y': _day.year,
                  }),
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (_sundayEntries.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _sundayEntries.first.name,
                  style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: palette.accent),
                ),
                for (final special in _sundayEntries.where((e) => e.isSpecial))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(context.trf('wo_special', {'name': special.name}),
                        style: TextStyle(fontSize: 13.5, color: palette.muted)),
                  ),
              ],
              if (season != null) ...[
                const SizedBox(height: 16),
                SeasonCard(
                  instance: season,
                  onTap: () =>
                      _open(LiturgicalPeriodDetailScreen(instance: season)),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: SectionTitle(context.tr('wo_hymns'))),
                  if (_lists.isNotEmpty)
                    TextButton(
                        onPressed: _chooseList, child: Text(context.tr('rp_change'))),
                ],
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (list == null)
                AppCard(
                  child: AppRow(
                    icon: Icons.queue_music_outlined,
                    title: _lists.isEmpty
                        ? context.tr('wo_prepare')
                        : context.tr('wo_choose'),
                    subtitle: _lists.isEmpty
                        ? context.tr('wo_prepare_sub')
                        : context.trf('wo_lists_avail', {'n': _lists.length}),
                    onTap: _chooseList,
                  ),
                )
              else if (_hymns.isEmpty)
                AppCard(
                  child: AppRow(
                    icon: Icons.queue_music_outlined,
                    title: list.name,
                    subtitle: context.tr('wo_empty_list'),
                    onTap: () => _open(const HymnListsScreen()),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    list.name,
                    style: TextStyle(fontSize: 13.5, color: palette.muted),
                  ),
                ),
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < _hymns.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: palette.border),
                        ResultRow(
                          leading: NumberBadge(_hymns[i].number),
                          title: _hymns[i].title,
                          trailing: _hymns[i].audioUrl != null ? const HymnAudioMark() : null,
                          onTap: () => _sing(i),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text(context.tr('wo_start')),
                  onPressed: () => _sing(0),
                ),
              ],
              const SizedBox(height: 24),
              SectionTitle(context.tr('wo_prayers')),
              AppRowGroup(rows: [
                for (final text in _prayers)
                  AppRow(
                    icon: churchTextIcon(text.icon),
                    title: text.title,
                    subtitle: text.subtitle,
                    onTap: () => _open(ChurchTextScreen(text: text)),
                  ),
                AppRow(
                  icon: Icons.auto_stories_outlined,
                  title: context.tr('wo_all_texts'),
                  onTap: () => _open(const ChurchTextsScreen()),
                ),
              ]),
              const SizedBox(height: 24),
              SectionTitle(context.tr('wo_prepare_service')),
              AppRowGroup(rows: [
                for (final text in [
                  BookOfWorshipData.sundayOrder,
                  BookOfWorshipData.greetingsPrayers,
                  BookOfWorshipData.confessionOfSin,
                  BookOfWorshipData.blessingsClosing,
                  BookOfWorshipData.litanyChurchWorld,
                ])
                  AppRow(
                    icon: churchTextIcon(text.icon),
                    title: text.title,
                    subtitle: text.subtitle,
                    onTap: () => _open(ChurchTextScreen(text: text)),
                  ),
              ]),
              const SizedBox(height: 24),
              SectionTitle(context.tr('wo_flow')),
              AppCard(
                child: Theme(
                  // No divider lines around the expanded step.
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: Column(
                    children: [
                      for (var i = 0; i < WorshipOrderData.steps.length; i++)
                        ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          expandedAlignment: Alignment.centerLeft,
                          leading: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.accentSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: palette.accent,
                              ),
                            ),
                          ),
                          title: Text(
                            WorshipOrderData.steps[i].title,
                            style: const TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w600),
                          ),
                          children: [
                            Text(
                              WorshipOrderData.steps[i].description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5 * lineHeight,
                                color: scheme.onSurface,
                              ),
                            ),
                            ChurchTextLinks(
                                textIds: WorshipOrderData.steps[i].textIds),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InfoNote(WorshipOrderData.introNote, lineHeightScale: lineHeight),
            ],
          ),
        ),
      ),
    );
  }
}
