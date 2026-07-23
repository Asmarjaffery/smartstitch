import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartstitch/ai/models/ai_message.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  final void Function(String text)? onRewrite;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onRewrite,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _Avatar(),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showOptions(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primary
                      : message.isError
                          ? theme.colorScheme.errorContainer
                          : theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.text.trim().isNotEmpty)
                            MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 14.5,
                                  height: 1.4,
                                ),
                                strong: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                code: TextStyle(
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.08),
                                  color: AppColors.primary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          // Rider contact card — official Uber/InDrive style,
                          // with Call + Share Location (inline map) actions.
                          if (message.actionType == 'call' &&
                              message.actionValue != null &&
                              message.actionValue!.isNotEmpty) ...[
                            _RiderCallCard(
                              phone: message.actionValue!,
                              name: message.actionMeta?['riderName'] ??
                                  'Your Rider',
                              photoUrl: message.actionMeta?['riderPhoto'],
                              statusLabel:
                                  message.actionMeta?['riderStatus'] ??
                                      'On the way',
                              onCall: () => _makeCall(message.actionValue!),
                            ),
                          ],
                          // Customer contact card — shown in the RIDER's
                          // chat when a customer taps "Ask AI to Call
                          // Rider". Same InDrive-style card, but the map
                          // (if coords are known) points at the customer's
                          // delivery location instead of a live GPS share.
                          if (message.actionType == 'call_customer' &&
                              message.actionValue != null &&
                              message.actionValue!.isNotEmpty) ...[
                            _CustomerCallCard(
                              phone: message.actionValue!,
                              name: message.actionMeta?['customerName'] ??
                                  'Customer',
                              statusLabel:
                                  message.actionMeta?['customerStatus'] ??
                                      'Wants to talk to you',
                              latitude: double.tryParse(
                                  message.actionMeta?['lat'] ?? ''),
                              longitude: double.tryParse(
                                  message.actionMeta?['lng'] ?? ''),
                              onCall: () => _makeCall(message.actionValue!),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) const SizedBox(width: 28),
        ],
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (!message.isUser && onRewrite != null)
              ListTile(
                leading: const Icon(Icons.auto_fix_high_rounded),
                title: const Text('Rewrite / Transform'),
                onTap: () {
                  Navigator.pop(context);
                  onRewrite?.call(message.text);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primary.withOpacity(0.15),
        child: Icon(Icons.auto_awesome_rounded,
            size: 16, color: AppColors.primary),
      );
}

// ─── Rider Call Card (Uber/InDrive-style official card) ──────────────────
// Stateful: "Share location" expands an inline map inside the same card.
// A small round share icon sits on the map itself (top-right corner)
// instead of a separate full-width button.

class _RiderCallCard extends StatefulWidget {
  final String phone;
  final String name;
  final String? photoUrl;
  final String statusLabel;
  final VoidCallback onCall;

  const _RiderCallCard({
    required this.phone,
    required this.name,
    required this.photoUrl,
    required this.statusLabel,
    required this.onCall,
  });

  @override
  State<_RiderCallCard> createState() => _RiderCallCardState();
}

class _RiderCallCardState extends State<_RiderCallCard> {
  bool _showMap = false;
  bool _isLoading = false;
  String? _error;
  LatLng? _location;

  Future<void> _handleShareLocationTap() async {
    if (_showMap) {
      // Already expanded — collapse it back.
      setState(() => _showMap = false);
      return;
    }

    setState(() {
      _showMap = true;
      _isLoading = true;
      _error = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied';
          _isLoading = false;
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Please enable location services';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _location = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareNow() async {
    if (_location == null) return;
    final mapsUrl =
        'https://www.google.com/maps?q=${_location!.latitude},${_location!.longitude}';

    await SharePlus.instance.share(
      ShareParams(
        text: 'Yahan hai meri current location:\n$mapsUrl',
        subject: 'My Location',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface2 : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Rider info row ──
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                backgroundImage:
                    (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                        ? NetworkImage(widget.photoUrl!)
                        : null,
                child: (widget.photoUrl == null || widget.photoUrl!.isEmpty)
                    ? Text(
                        widget.name.isNotEmpty
                            ? widget.name[0].toUpperCase()
                            : 'R',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.statusLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.delivery_dining_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'Your delivery rider',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: widget.onCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('Call',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _handleShareLocationTap,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _showMap ? AppColors.primary : borderColor,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      _showMap
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.location_on_rounded,
                      color: _showMap
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.black87),
                      size: 16,
                    ),
                    label: Text(
                      _showMap ? 'Hide map' : 'Share location',
                      style: TextStyle(
                        color: _showMap
                            ? AppColors.primary
                            : (isDark ? Colors.white : Colors.black87),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Inline expanding map ──────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: !_showMap
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _isLoading
                        ? const SizedBox(
                            height: 140,
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          )
                        : _error != null
                            ? SizedBox(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 140,
                                  child: Stack(
                                    children: [
                                      FlutterMap(
                                        options: MapOptions(
                                          initialCenter: _location!,
                                          initialZoom: 16,
                                          interactionOptions:
                                              const InteractionOptions(
                                            flags: InteractiveFlag.pinchZoom |
                                                InteractiveFlag.drag,
                                          ),
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.smartstitch.app',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: _location!,
                                                width: 36,
                                                height: 36,
                                                child: const Icon(
                                                  Icons.location_on_rounded,
                                                  color: AppColors.primary,
                                                  size: 36,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // ── Small share icon, top-right corner ──
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: _shareNow,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.share_rounded,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Call Card (rider-side, InDrive-style) ───────────────────────
// Shown inside the RIDER's own AI Assistant chat the moment a customer
// requests a call. No live GPS fetch here — the customer's delivery
// coordinates (if known) come straight from the booking, so the map (when
// expanded) is instant instead of waiting on a location permission prompt.
class _CustomerCallCard extends StatefulWidget {
  final String phone;
  final String name;
  final String statusLabel;
  final double? latitude;
  final double? longitude;
  final VoidCallback onCall;

  const _CustomerCallCard({
    required this.phone,
    required this.name,
    required this.statusLabel,
    required this.latitude,
    required this.longitude,
    required this.onCall,
  });

  @override
  State<_CustomerCallCard> createState() => _CustomerCallCardState();
}

class _CustomerCallCardState extends State<_CustomerCallCard> {
  bool _showMap = false;

  bool get _hasLocation => widget.latitude != null && widget.longitude != null;

  void _toggleMap() => setState(() => _showMap = !_showMap);

  Future<void> _openDirections() async {
    if (!_hasLocation) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface2 : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Customer info row ──
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Calling',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.person_pin_circle_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            widget.statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: widget.onCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.call_rounded,
                        color: Colors.white, size: 16),
                    label: const Text('Call',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _toggleMap,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _showMap ? AppColors.primary : borderColor,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      _showMap
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.location_on_rounded,
                      color: _showMap
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.black87),
                      size: 16,
                    ),
                    label: Text(
                      _showMap ? 'Hide map' : 'Show map',
                      style: TextStyle(
                        color: _showMap
                            ? AppColors.primary
                            : (isDark ? Colors.white : Colors.black87),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Inline expanding map ──────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: !_showMap
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: !_hasLocation
                        ? SizedBox(
                            height: 60,
                            child: Center(
                              child: Text(
                                'Customer location isn\'t available yet',
                                style: TextStyle(
                                    fontSize: 12.5, color: textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 140,
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                          widget.latitude!, widget.longitude!),
                                      initialZoom: 16,
                                      interactionOptions:
                                          const InteractionOptions(
                                        flags: InteractiveFlag.pinchZoom |
                                            InteractiveFlag.drag,
                                      ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.smartstitch.app',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(widget.latitude!,
                                                widget.longitude!),
                                            width: 36,
                                            height: 36,
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              color: AppColors.primary,
                                              size: 36,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // ── Directions icon, top-right corner ──
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: _openDirections,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.directions_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}