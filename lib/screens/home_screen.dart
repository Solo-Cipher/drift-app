import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_data.dart';
import '../data/trip_generator.dart';
import '../services/closure_checker.dart';
import '../screens/day_detail_screen.dart';
import '../screens/cost_screen.dart';
import '../screens/trip_editor_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/smart_alerts_screen.dart';
import '../screens/poi_manager_screen.dart';
import '../screens/create_or_join_group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TripData? _trip; // null = new user, no country selected
  late AnimationController _headerAnimController;
  late AnimationController _listAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  String tripTypeLabel = 'Couple Trip';
  IconData tripTypeIcon = Icons.favorite;
  String currency = 'OMR';

  // Only valid when _trip != null
  TripData get trip => _trip!;

  // Inline editing state
  int? _expandedDayIndex;
  bool _isEditing = false;
  late TextEditingController _editTitleController;
  late TextEditingController _editLocationController;
  late TextEditingController _editDescController;
  List<TextEditingController> _activityControllers = [];
  List<ActivityLocation?> _activityLocations = [];

  // Notifications
  List<ClosureNotification> _notifications = [];
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _trip = null; // Empty for new users
    _headerAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _listAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _headerFade = CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut));
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _listAnimController.forward();
    });
    _editTitleController = TextEditingController();
    _editLocationController = TextEditingController();
    _editDescController = TextEditingController();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _listAnimController.dispose();
    _editTitleController.dispose();
    _editLocationController.dispose();
    _editDescController.dispose();
    for (final c in _activityControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Trip lifecycle ──────────────────────────────────────

  void _onTripSaved(TripData newTrip) {
    setState(() {
      _trip = newTrip;
      _notifications = checkClosures(trip);
      _listAnimController.forward();
    });
  }

  // ─── Inline editing ──────────────────────────────────────

  void _startEditing(int index) {
    final day = trip.days[index];
    setState(() {
      _expandedDayIndex = index;
      _isEditing = true;
      _editTitleController.text = day.title;
      _editLocationController.text = day.location;
      _editDescController.text = day.description;
      for (final c in _activityControllers) {
        c.dispose();
      }
      _activityControllers = day.activities.map((a) => TextEditingController(text: a)).toList();
      _activityLocations = List<ActivityLocation?>.from(day.activityLocations);
      while (_activityLocations.length < _activityControllers.length) {
        _activityLocations.add(null);
      }
    });
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  void _saveEditing() {
    if (_expandedDayIndex == null) return;
    final index = _expandedDayIndex!;
    final day = trip.days[index];
    final newActivities = _activityControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

    setState(() {
      final days = List<TripDay>.from(trip.days);
      days[index] = day.copyWith(
        title: _editTitleController.text,
        location: _editLocationController.text,
        description: _editDescController.text,
        activities: newActivities,
        activityLocations: _activityLocations,
      );
      _trip = trip.copyWith(days: days);
      _isEditing = false;
      _notifications = checkClosures(trip);
    });
  }

  void _addActivityInline() {
    setState(() {
      _activityControllers.add(TextEditingController(text: 'New activity'));
      _activityLocations.add(null);
    });
  }

  void _removeActivityInline(int index) {
    setState(() {
      _activityControllers[index].dispose();
      _activityControllers.removeAt(index);
      if (index < _activityLocations.length) {
        _activityLocations.removeAt(index);
      }
    });
  }

  // ─── Notification FAB sheet ──────────────────────────────

  void _showNotificationSheet(BuildContext context) {
    final closures = _notifications.where((n) => n.type == NotificationType.closure).toList();
    final tickets = _notifications.where((n) => n.type == NotificationType.ticket).toList();
    final timings = _notifications.where((n) => n.type == NotificationType.timing).toList();
    final infos = _notifications.where((n) => n.type == NotificationType.info).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Text('Trip Notifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                    const Spacer(),
                    if (_notifications.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: closures.isNotEmpty
                              ? const Color(0xFFFF6B6B).withOpacity(0.1)
                              : const Color(0xFFFFAB40).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${_notifications.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: closures.isNotEmpty ? const Color(0xFFFF6B6B) : const Color(0xFFFFAB40))),
                      ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFEEEEEE)),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF00BFA6)),
                            const SizedBox(height: 12),
                            Text('All clear!', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
                            Text('No schedule conflicts or ticket reminders.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888))),
                          ],
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (closures.isNotEmpty) ...[
                            _buildNotificationSectionHeader('� Closures', const Color(0xFFFF6B6B)),
                            ...closures.map((n) => _buildNotificationCard(n)),
                            const SizedBox(height: 16),
                          ],
                          if (tickets.isNotEmpty) ...[
                            _buildNotificationSectionHeader('🎫 Tickets Required', const Color(0xFF6C63FF)),
                            ...tickets.map((n) => _buildNotificationCard(n)),
                            const SizedBox(height: 16),
                          ],
                          if (timings.isNotEmpty) ...[
                            _buildNotificationSectionHeader('� Timing Warnings', const Color(0xFFFFAB40)),
                            ...timings.map((n) => _buildNotificationCard(n)),
                            const SizedBox(height: 16),
                          ],
                          if (infos.isNotEmpty) ...[
                            _buildNotificationSectionHeader('ℹ️ Info', const Color(0xFF00BFA6)),
                            ...infos.map((n) => _buildNotificationCard(n)),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildNotificationCard(ClosureNotification n) {
    final color = n.risk == ClosureRisk.closed
        ? const Color(0xFFFF6B6B)
        : n.risk == ClosureRisk.warning
            ? const Color(0xFFFFAB40)
            : const Color(0xFF6C63FF);
    final icon = n.risk == ClosureRisk.closed
        ? Icons.error
        : n.risk == ClosureRisk.warning
            ? Icons.warning_amber
            : Icons.info_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(n.venue, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                    const Spacer(),
                    Text('Day ${n.dayNumber}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF999999))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(n.dayDate, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF888888))),
                const SizedBox(height: 4),
                Text(n.message, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF555555), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MAIN BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_trip == null) return _buildWelcomeScreen(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildOverviewCards(context)),
          SliverToBoxAdapter(child: _buildSectionHeader('Itinerary', Icons.calendar_today)),
          _buildTimeline(context),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton.small(
                heroTag: 'notifications',
                onPressed: () => _showNotificationSheet(context),
                backgroundColor: _notifications.any((n) => n.risk == ClosureRisk.closed)
                    ? const Color(0xFFFF6B6B)
                    : _notifications.any((n) => n.risk == ClosureRisk.warning)
                        ? const Color(0xFFFFAB40)
                        : const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                child: const Icon(Icons.notifications_outlined),
              ),
              if (_notifications.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_notifications.length}', style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'expenses',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrJoinGroupScreen())),
            backgroundColor: const Color(0xFF00BFA6),
            foregroundColor: Colors.white,
            child: const Icon(Icons.groups),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'edit',
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TripEditorScreen(trip: trip)));
              if (result != null) _onTripSaved(result);
            },
            backgroundColor: const Color(0xFF00BFA6),
            foregroundColor: Colors.white,
            child: const Icon(Icons.edit),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'budget',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CostScreen(trip: trip))),
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Budget'),
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // WELCOME SCREEN (empty state)
  // ══════════════════════════════════════════════════════════

  Widget _buildWelcomeScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6C63FF), Color(0xFF4A42D0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore, size: 64, color: Colors.white70),
                  const SizedBox(height: 24),
                  Text('D R I F T',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 6)),
                  const SizedBox(height: 8),
                  Text('Plan Your Next Adventure',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('Select a country to generate your itinerary.\nSmart alerts, budget tracking, and expense sharing — all in one place.',
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: () => _openTripEditor(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Plan a Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTripEditor(BuildContext context) async {
    final dummyTrip = _trip ?? TripGenerator.generate(countryKey: 'vietnam', startDate: DateTime.now().add(const Duration(days: 30)), endDate: DateTime.now().add(const Duration(days: 40)));
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TripEditorScreen(trip: dummyTrip)));
    if (result != null && result is TripData) {
      _onTripSaved(result);
    }
  }

  // ══════════════════════════════════════════════════════════
  // ITINERARY VIEWS
  // ══════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF6C63FF),
      actions: [
        IconButton(
          icon: const Icon(Icons.insights, color: Colors.white),
          tooltip: 'Smart Alerts',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SmartAlertsScreen(trip: trip))),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(trip: trip)));
            if (result != null && result is Map) {
              setState(() {
                tripTypeLabel = result['tripType'] ?? tripTypeLabel;
                tripTypeIcon = result['tripTypeIcon'] ?? tripTypeIcon;
                currency = result['currency'] ?? currency;
              });
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF4A42D0), Color(0xFF3B35A8)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 40),
                      Text('D R I F T', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 6)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('✈️ ${trip.startDate} — ${trip.endDate}', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 12),
                      Text(trip.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
                      const SizedBox(height: 8),
                      Text(trip.subtitle, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(tripTypeIcon, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('$tripTypeLabel  •  ${trip.totalDays} days', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    double totalTransport = 0, totalAccommodation = 0, totalFood = 0;
    for (final day in trip.days) {
      if (day.transportCost != null) totalTransport += double.tryParse(day.transportCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (day.accommodationCost != null) totalAccommodation += double.tryParse(day.accommodationCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (day.foodCost != null) totalFood += double.tryParse(day.foodCost!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    }
    final total = totalTransport + totalAccommodation + totalFood;
    final perPerson = total > 0 ? total / 2 : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6C63FF), Color(0xFF4A42D0)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Budget', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(currency, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${total.toStringAsFixed(0)} $currency', style: GoogleFonts.inter(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                Text('~${perPerson.toStringAsFixed(0)} $currency per person', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 16),
                if (total > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        _buildBarSegment(totalTransport / total, const Color(0xFFFFAB40)),
                        _buildBarSegment(totalAccommodation / total, const Color(0xFF00BFA6)),
                        _buildBarSegment(totalFood / total, const Color(0xFFFF6B6B)),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildBarLegend('Transport', const Color(0xFFFFAB40)),
                    const SizedBox(width: 16),
                    _buildBarLegend('Hotels', const Color(0xFF00BFA6)),
                    const SizedBox(width: 16),
                    _buildBarLegend('Food', const Color(0xFFFF6B6B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarSegment(double fraction, Color color) {
    return Expanded(
      flex: (fraction * 100).round().clamp(1, 100),
      child: Container(height: 6, color: color),
    );
  }

  Widget _buildBarLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final day = trip.days[index];
          final isExpanded = _expandedDayIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isExpanded ? const Color(0xFF6C63FF) : const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _expandedDayIndex = isExpanded ? null : index;
                    _isEditing = false;
                  }),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: day.color.withOpacity(0.1), shape: BoxShape.circle),
                          child: Center(child: Text('${day.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: day.color))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                              Text('${day.location} • ${day.date}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF999999))),
                            ],
                          ),
                        ),
                        if (day.isTravelDay)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.flight, size: 14, color: const Color(0xFF6C63FF)),
                          ),
                        Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: const Color(0xFFCCCCCC)),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEditing) ...[
                          Text(day.description, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555), height: 1.5)),
                          if (day.activities.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...day.activities.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF00BFA6)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(a, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            )),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSmallButton(Icons.edit, 'Edit', () => _startEditing(index)),
                              const SizedBox(width: 8),
                              _buildSmallButton(Icons.place, 'Places', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PoiManagerScreen(
                                trip: trip,
                                dayNumber: day.day,
                                onSave: (_) => setState(() {}),
                              )))),
                              const SizedBox(width: 8),
                              _buildSmallButton(Icons.open_in_new, 'Details', () => Navigator.push(context, MaterialPageRoute(builder: (_) => DayDetailScreen(day: day, tripTitle: trip.title)))),
                            ],
                          ),
                        ] else ...[
                          // Inline editing UI
                          TextField(controller: _editTitleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _editLocationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _editDescController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                          const SizedBox(height: 12),
                          ..._activityControllers.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(child: TextField(controller: entry.value, decoration: const InputDecoration(labelText: 'Activity', border: OutlineInputBorder(), isDense: true))),
                                IconButton(icon: const Icon(Icons.remove_circle, size: 18, color: Colors.red), onPressed: () => _removeActivityInline(entry.key)),
                              ],
                            ),
                          )),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(onPressed: _addActivityInline, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
                              const Spacer(),
                              TextButton(onPressed: _cancelEditing, child: const Text('Cancel')),
                              const SizedBox(width: 8),
                              ElevatedButton(onPressed: _saveEditing, child: const Text('Save')),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        childCount: trip.days.length,
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF))),
          ],
        ),
      ),
    );
  }
}
