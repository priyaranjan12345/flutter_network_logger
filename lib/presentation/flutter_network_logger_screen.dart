import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../entity/log_entry.dart';
import '../provider/flutter_network_logger_notifier.dart';

class FlutterNetworkLoggerScreen extends StatelessWidget {
  const FlutterNetworkLoggerScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FlutterNetworkLoggerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => FlutterNetworkLoggerNotifier.instance.clear(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: FlutterNetworkLoggerNotifier.instance,
        builder: (context, _) {
          final logs = FlutterNetworkLoggerNotifier.instance.logs;
          if (logs.isEmpty) {
            return const Center(child: Text('No network requests yet'));
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _LogTile(entry: logs[index]),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final LogEntry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return ListTile(
      dense: true,
      leading: _MethodBadge(method: entry.method, color: color),
      title: Text(
        entry.url.path.isEmpty ? '/' : entry.url.path,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
      ),
      subtitle: Text(
        '${entry.url.host} • ${entry.duration?.inMilliseconds ?? '...'}ms',
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      trailing: Text(
        entry.statusCode?.toString() ?? (entry.error != null ? 'ERR' : '•••'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 13,
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _LogDetailScreen(entry: entry)),
      ),
    );
  }

  Color get _statusColor {
    if (entry.error != null) return Colors.red;
    if (entry.statusCode == null) return Colors.orange;
    if (entry.statusCode! < 300) return Colors.green;
    if (entry.statusCode! < 400) return Colors.orange;
    return Colors.red;
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  final Color color;
  const _MethodBadge({required this.method, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _LogDetailScreen extends StatelessWidget {
  final LogEntry entry;
  const _LogDetailScreen({required this.entry});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${entry.method} ${entry.url.path}',
            style: const TextStyle(fontSize: 14),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(entry: entry),
            _RequestTab(entry: entry),
            _ResponseTab(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final LogEntry entry;
  const _OverviewTab({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow('URL', entry.url.toString()),
        _InfoRow('Method', entry.method),
        _InfoRow('Status', entry.statusCode?.toString() ?? 'Pending'),
        _InfoRow(
          'Duration',
          entry.duration != null
              ? '${entry.duration!.inMilliseconds}ms'
              : 'N/A',
        ),
        _InfoRow('Request Time', entry.requestTime.toIso8601String()),
        if (entry.responseTime != null)
          _InfoRow('Response Time', entry.responseTime!.toIso8601String()),
        if (entry.error != null) _InfoRow('Error', entry.error!, isError: true),
      ],
    );
  }
}

class _RequestTab extends StatelessWidget {
  final LogEntry entry;
  const _RequestTab({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader('Headers', entry.requestHeaders.toString()),
        ...entry.requestHeaders.entries.map((e) => _InfoRow(e.key, e.value)),
        const SizedBox(height: 16),
        _SectionHeader('Body', entry.formattedRequestBody),
        if (entry.requestBody != null)
          _CodeBlock(entry.formattedRequestBody)
        else
          const Text('No request body', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _ResponseTab extends StatelessWidget {
  final LogEntry entry;
  const _ResponseTab({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (!entry.isComplete) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (entry.responseHeaders != null) ...[
          _SectionHeader('Headers', entry.responseHeaders.toString()),
          ...entry.responseHeaders!.entries.map(
            (e) => _InfoRow(e.key, e.value),
          ),
          const SizedBox(height: 16),
        ],
        _SectionHeader('Body', entry.formattedResponseBody),
        if (entry.responseBody != null)
          _CodeBlock(entry.formattedResponseBody)
        else
          const Text('No response body', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;
  const _InfoRow(this.label, this.value, {this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isError ? Colors.red : null,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String copyContent;
  const _SectionHeader(this.title, this.copyContent);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: copyContent));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock(this.code);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}
