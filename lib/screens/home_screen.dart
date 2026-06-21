import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_data.dart';
import '../data/vietnam_trip.dart';
import '../services/closure_checker.dart';
import '../widgets/location_autocomplete_field.dart';
import '../screens/day_detail_screen.dart';
import '../screens/cost_screen.dart';
import '../screens/trip_editor_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/smart_alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TripData trip;
  late AnimationController _headerAnimController;
  late AnimationController _listAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  String tripTypeLabel = 'Couple Trip';
  IconData tripTypeIcon = Icons.favorite;
  String currency = 'OMR';

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
    trip = getVietnamTrip();
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
    _notifications = checkClosures(trip);
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
    setState(() {
      _isEditing = false;
    });
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
      trip = trip.copyWith(days: days);
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

  void _showNotificationSheet(BuildContext context) {
    // Group notifications by type
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
                            _buildNotificationSectionHeader('🚨 Closures', const Color(0xFFFF6B6B)),
                            ...closures.map((n) => _buildNotificationCard(n)),
                            const SizedBox(height: 16),
                          ],
                          if (tickets.isNotEmpty) ...[
                            _buildNotificationSectionHeader('🎫 Tickets Required', const Color(0xFF6C63FF)),
                            ...tickets.map((n) => _buildNotificationCard(n)),
                            const SizedBox(height: 16),
                          ],
                          if (timings.isNotEmpty) ...[
                            _buildNotificationSectionHeader('⏰ Timing Warnings', const Color(0xFFFFAB40)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildOverviewCards(context)),
          SliverToBoxAdapter(child: _buildSectionHeader('Itinerary', Icons.map)),
          _buildTimeline(context),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notification bell with badge
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
                    child: Text(
                      '${_notifications.length}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'edit',
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TripEditorScreen(trip: trip)));
              if (result != null) {
                setState(() {
                  trip = result;
                  _notifications = checkClosures(trip);
                });
              }
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
    final totalActivities = trip.days.fold(0, (sum, d) => sum + d.activities.length);

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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoTile(icon: Icons.local_activity, value: '$totalActivities', label: 'Activities', color: const Color(0xFF00BFA6))),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoTile(icon: Icons.directions, value: '${trip.days.where((d) => d.isTravelDay).length}', label: 'Travel Days', color: const Color(0xFFFFAB40))),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showNotificationSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _notifications.any((n) => n.risk == ClosureRisk.closed)
                            ? const Color(0xFFFF6B6B).withOpacity(0.3)
                            : _notifications.any((n) => n.risk == ClosureRisk.warning)
                                ? const Color(0xFFFFAB40).withOpacity(0.3)
                                : const Color(0xFFEEEEEE),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _notifications.any((n) => n.risk == ClosureRisk.closed)
                                ? const Color(0xFFFF6B6B).withOpacity(0.1)
                                : _notifications.any((n) => n.risk == ClosureRisk.warning)
                                    ? const Color(0xFFFFAB40).withOpacity(0.1)
                                    : const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _notifications.any((n) => n.risk == ClosureRisk.closed)
                                ? Icons.error_outline
                                : _notifications.any((n) => n.risk == ClosureRisk.warning)
                                    ? Icons.warning_amber_outlined
                                    : Icons.notifications_outlined,
                            size: 20,
                            color: _notifications.any((n) => n.risk == ClosureRisk.closed)
                                ? const Color(0xFFFF6B6B)
                                : _notifications.any((n) => n.risk == ClosureRisk.warning)
                                    ? const Color(0xFFFFAB40)
                                    : const Color(0xFF6C63FF),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _notifications.isEmpty ? 'All Clear' : '${_notifications.length} Alert${_notifications.length > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _notifications.any((n) => n.risk == ClosureRisk.closed)
                                ? const Color(0xFFFF6B6B)
                                : _notifications.any((n) => n.risk == ClosureRisk.warning)
                                    ? const Color(0xFFFFAB40)
                                    : const Color(0xFF6C63FF),
                          ),
                        ),
                        Text('Schedule', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF888888))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarSegment(double fraction, Color color) {
    return Expanded(flex: (fraction * 100).round().clamp(1, 100), child: Container(height: 6, color: color));
  }

  Widget _buildBarLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  Widget _buildInfoTile({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: color)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(children: [Icon(icon, size: 20, color: const Color(0xFF6C63FF)), const SizedBox(width: 8), Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)))]),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final day = trip.days[index];
          final isLast = index == trip.days.length - 1;
          final isExpanded = _expandedDayIndex == index;
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _listAnimController, curve: Interval((index / trip.days.length) * 0.8, (index / trip.days.length) * 0.8 + 0.2, curve: Curves.easeOut))),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _listAnimController, curve: Interval((index / trip.days.length) * 0.8, (index / trip.days.length) * 0.8 + 0.2)),
              child: _buildDayCard(context, day, index, isLast, isExpanded),
            ),
          );
        },
        childCount: trip.days.length,
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, TripDay day, int index, bool isLast, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline dot
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  if (index > 0) Expanded(child: Container(width: 2, color: const Color(0xFFE0E0E0))),
                  if (index == 0) const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_isEditing) return;
                      setState(() {
                        _expandedDayIndex = _expandedDayIndex == index ? null : index;
                      });
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: day.color, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: day.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Center(child: Text('${day.day}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                    ),
                  ),
                  if (!isLast) Expanded(child: Container(width: 2, color: const Color(0xFFE0E0E0))),
                  if (isLast) const Spacer(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Card content
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isEditing) return;
                  setState(() {
                    _expandedDayIndex = _expandedDayIndex == index ? null : index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
                    border: isExpanded ? Border.all(color: day.color.withOpacity(0.3), width: 1.5) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Always visible: header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: day.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(day.icon, size: 18, color: day.color)),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(day.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
                                  Text('${day.date} · ${day.location}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888))),
                                ])),
                                if (day.isTravelDay) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('TRAVEL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF), letterSpacing: 0.5))),
                                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: const Color(0xFFCCCCCC)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(day.description, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF555555), height: 1.4), maxLines: isExpanded ? null : 2, overflow: isExpanded ? null : TextOverflow.ellipsis),
                          ],
                        ),
                      ),

                      // Expanded: transportation section (replaces activities)
                      if (isExpanded && !_isEditing) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Transportation section
                              if (day.arrivalTransport != null || day.departureTransport != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.directions, size: 14, color: Color(0xFF6C63FF)),
                                    const SizedBox(width: 6),
                                    Text('Transportation', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FE),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEEEEEE)),
                                  ),
                                  child: Column(
                                    children: [
                                      if (day.arrivalTransport != null)
                                        _buildTransportRow('Arrival', day.arrivalTransport!),
                                      if (day.arrivalTransport != null && day.departureTransport != null)
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)),
                                      if (day.departureTransport != null)
                                        _buildTransportRow('Departure', day.departureTransport!),
                                      if (day.transportDuration != null || day.transportCost != null) ...[
                                        const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1)),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (day.transportDuration != null)
                                              Row(children: [
                                                const Icon(Icons.access_time, size: 12, color: Color(0xFF888888)),
                                                const SizedBox(width: 4),
                                                Text(day.transportDuration!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666))),
                                              ]),
                                            if (day.transportCost != null)
                                              Text('${day.transportCost} $currency', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF6C63FF))),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // Activities preview
                              if (day.activities.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.local_activity, size: 14, color: Color(0xFF00BFA6)),
                                    const SizedBox(width: 6),
                                    Text('Activities', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF00BFA6))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...day.activities.take(3).map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(children: [
                                    Container(width: 4, height: 4, decoration: BoxDecoration(color: day.color.withOpacity(0.5), shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(a, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF555555)))),
                                  ]),
                                )),
                                if (day.activities.length > 3)
                                  Text('+${day.activities.length - 3} more', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                              ],

                              // Inline map preview showing day's locations
                              _buildInlineMapPreview(day),
                            ],
                          ),
                        ),
                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _startEditing(index),
                                icon: const Icon(Icons.edit, size: 14),
                                label: Text('Edit', style: GoogleFonts.inter(fontSize: 12)),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C63FF), padding: const EdgeInsets.symmetric(horizontal: 8)),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DayDetailScreen(day: day, tripTitle: trip.title, currency: trip.currency))),
                                icon: const Icon(Icons.map, size: 14),
                                label: Text('Map View', style: GoogleFonts.inter(fontSize: 12)),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF00BFA6), padding: const EdgeInsets.symmetric(horizontal: 8)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Edit mode
                      if (isExpanded && _isEditing) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _editTitleController,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Title', labelStyle: GoogleFonts.inter(fontSize: 12),
                                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _editLocationController,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Location', labelStyle: GoogleFonts.inter(fontSize: 12),
                                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _editDescController,
                                maxLines: 2,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Description', labelStyle: GoogleFonts.inter(fontSize: 12),
                                  isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('Activities', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF888888))),
                              const SizedBox(height: 6),
                              ..._activityControllers.asMap().entries.map((entry) {
                                final actIndex = entry.key;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: LocationAutocompleteField(
                                          initialValue: entry.value.text,
                                          dense: true,
                                          onLocationSelected: (loc) {
                                            setState(() {
                                              if (actIndex < _activityLocations.length) {
                                                _activityLocations[actIndex] = loc;
                                              }
                                            });
                                          },
                                          onChanged: (v) => entry.value.text = v,
                                          currentLocation: actIndex < _activityLocations.length ? _activityLocations[actIndex] : null,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Color(0xFFCCCCCC)),
                                        onPressed: () => _removeActivityInline(actIndex),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              TextButton.icon(
                                onPressed: _addActivityInline,
                                icon: const Icon(Icons.add, size: 16, color: Color(0xFF6C63FF)),
                                label: Text('Add activity', style: GoogleFonts.inter(color: const Color(0xFF6C63FF), fontSize: 13)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _cancelEditing,
                                    child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF999999))),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _saveEditing,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportRow(String label, TransportMode mode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: getTransportColor(mode).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(getTransportIcon(mode), size: 14, color: getTransportColor(mode)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF999999))),
            Text(getTransportLabel(mode), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF333333))),
          ],
        ),
      ],
    );
  }

  Widget _buildTransportChip(TransportMode mode, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: getTransportColor(mode).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(getTransportIcon(mode), size: 12, color: getTransportColor(mode)), const SizedBox(width: 4), Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: getTransportColor(mode)))]),
    );
  }

  /// Build inline map preview for a day card
  Widget _buildInlineMapPreview(TripDay day) {
    final pins = day.allPins;
    if (pins.isEmpty) return const SizedBox.shrink();

    // Register the iframe view factory for this day
    final iframeId = 'inline-map-day-${day.day}';
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      iframeId,
      (int viewId) {
        double minLat = pins.first.lat, maxLat = pins.first.lat;
        double minLng = pins.first.lng, maxLng = pins.first.lng;
        for (final p in pins) {
          if (p.lat < minLat) minLat = p.lat;
          if (p.lat > maxLat) maxLat = p.lat;
          if (p.lng < minLng) minLng = p.lng;
          if (p.lng > maxLng) maxLng = p.lng;
        }
        final bboxPadding = 0.02;
        final bbox = '${minLng - bboxPadding}%2C${minLat - bboxPadding}%2C${maxLng + bboxPadding}%2C${maxLat + bboxPadding}';
        final markers = pins.map((p) => 'marker=${p.lat}%2C${p.lng}').join('&');
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..src = 'https://www.openstreetmap.org/export/embed.html?bbox=$bbox&layer=mapnik&$markers';
        return iframe;
      },
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        color: const Color(0xFFE8EAF6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          HtmlElementView(viewType: iframeId),
          // Pin count badge overlay
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 12, color: day.color),
                  const SizedBox(width: 4),
                  Text(
                    pins.length == 1 ? '${pins.first.name}' : '${pins.length} places',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
                  ),
                ],
              ),
            ),
          ),
          // Open in maps button
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async {
                String url;
                if (pins.length == 1) {
                  url = 'https://www.google.com/maps/search/?api=1&query=${pins.first.lat},${pins.first.lng}';
                } else {
                  final center = pins.first;
                  final waypoints = pins.skip(1).map((p) => '${p.lat},${p.lng}').join('|');
                  url = 'https://www.google.com/maps/dir/${center.lat},${center.lng}/$waypoints';
                }
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 1))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: day.color),
                    const SizedBox(width: 4),
                    Text('Open Map', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: day.color)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
