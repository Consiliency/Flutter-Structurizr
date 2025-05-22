import 'dart:io';
import 'package:flutter/material.dart';
import '../../infrastructure/persistence/workspace_persistence_service.dart';
import '../../infrastructure/preferences/app_preferences.dart';
import '../../infrastructure/repositories/enhanced_file_workspace_repository.dart';

class MobileWorkspaceBrowser extends StatefulWidget {
  final Function(WorkspaceFileInfo)? onWorkspaceSelected;
  final Function(WorkspaceHistoryEntry)? onRecentWorkspaceSelected;
  final VoidCallback? onCreateNew;
  final VoidCallback? onImportFile;
  final bool isDarkMode;

  const MobileWorkspaceBrowser({
    super.key,
    this.onWorkspaceSelected,
    this.onRecentWorkspaceSelected,
    this.onCreateNew,
    this.onImportFile,
    this.isDarkMode = false,
  });

  @override
  State<MobileWorkspaceBrowser> createState() => _MobileWorkspaceBrowserState();
}

class _MobileWorkspaceBrowserState extends State<MobileWorkspaceBrowser> with TickerProviderStateMixin {
  late TabController _tabController;
  List<WorkspaceFileInfo> _workspaceFiles = [];
  List<WorkspaceHistoryEntry> _recentWorkspaces = [];
  WorkspaceRepositoryStatistics? _statistics;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = EnhancedFileWorkspaceRepository.instance;
      
      // Load workspace files, recent workspaces, and statistics in parallel
      final results = await Future.wait([
        repository.listWorkspaces(),
        repository.getWorkspaceHistory(),
        repository.getRepositoryStatistics(),
      ]);

      setState(() {
        _workspaceFiles = results[0] as List<WorkspaceFileInfo>;
        _recentWorkspaces = results[1] as List<WorkspaceHistoryEntry>;
        _statistics = results[2] as WorkspaceRepositoryStatistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(theme, colorScheme),
          _buildSearchBar(theme, colorScheme),
          _buildTabBar(theme, colorScheme),
          Expanded(
            child: _buildTabBarView(theme, colorScheme),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workspace Browser',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_statistics != null)
                  Text(
                    '${_statistics!.totalWorkspaces} workspaces • ${_formatFileSize(_statistics!.totalSizeBytes)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search workspaces...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Recent'),
          Tab(text: 'Info'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading workspaces...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading workspaces',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllWorkspacesTab(theme, colorScheme),
        _buildRecentWorkspacesTab(theme, colorScheme),
        _buildStatisticsTab(theme, colorScheme),
      ],
    );
  }

  Widget _buildAllWorkspacesTab(ThemeData theme, ColorScheme colorScheme) {
    final filteredWorkspaces = _workspaceFiles.where((workspace) {
      if (_searchQuery.isEmpty) return true;
      return workspace.fileName.toLowerCase().contains(_searchQuery) ||
             (workspace.metadata?.workspaceName.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (filteredWorkspaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No workspaces found' : 'No workspaces available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search terms'
                  : 'Create a new workspace or import an existing file',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredWorkspaces.length,
        itemBuilder: (context, index) {
          final workspace = filteredWorkspaces[index];
          return _buildWorkspaceCard(workspace, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildRecentWorkspacesTab(ThemeData theme, ColorScheme colorScheme) {
    final filteredRecent = _recentWorkspaces.where((workspace) {
      if (_searchQuery.isEmpty) return true;
      return workspace.workspaceName.toLowerCase().contains(_searchQuery) ||
             workspace.filePath.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredRecent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent workspaces',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open a workspace to see it here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecent.length,
        itemBuilder: (context, index) {
          final workspace = filteredRecent[index];
          return _buildRecentWorkspaceCard(workspace, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildStatisticsTab(ThemeData theme, ColorScheme colorScheme) {
    if (_statistics == null) {
      return const Center(child: Text('No statistics available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            'Total Workspaces',
            _statistics!.totalWorkspaces.toString(),
            Icons.folder,
            colorScheme.primary,
            theme,
            colorScheme,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Total Size',
            _formatFileSize(_statistics!.totalSizeBytes),
            Icons.storage,
            colorScheme.secondary,
            theme,
            colorScheme,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Workspace Directory',
            _statistics!.workspaceDirectory,
            Icons.folder_open,
            colorScheme.tertiary,
            theme,
            colorScheme,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Recent History',
            '${_statistics!.historyCount} entries',
            Icons.history,
            colorScheme.outline,
            theme,
            colorScheme,
          ),
          if (_statistics!.lastModified != null) ...[
            const SizedBox(height: 16),
            _buildStatCard(
              'Last Modified',
              _formatDate(_statistics!.lastModified!),
              Icons.schedule,
              colorScheme.surfaceContainerHighest,
              theme,
              colorScheme,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Format Distribution',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._statistics!.formatCounts.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    entry.key == WorkspaceFormat.dsl ? Icons.code : Icons.description,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.name.toUpperCase(),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value} files',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(WorkspaceFileInfo workspace, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => widget.onWorkspaceSelected?.call(workspace),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: workspace.format == WorkspaceFormat.dsl
                        ? colorScheme.primaryContainer
                        : colorScheme.secondaryContainer,
                    child: Icon(
                      workspace.format == WorkspaceFormat.dsl ? Icons.code : Icons.description,
                      color: workspace.format == WorkspaceFormat.dsl
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspace.metadata?.workspaceName ?? workspace.fileName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          workspace.fileName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleWorkspaceAction(value, workspace),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: ListTile(
                          leading: Icon(Icons.open_in_new),
                          title: Text('Open'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'details',
                        child: ListTile(
                          leading: Icon(Icons.info),
                          title: Text('Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workspace.lastModified != null
                        ? _formatDate(workspace.lastModified!)
                        : 'Unknown',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (workspace.fileSize != null) ...[
                    Icon(
                      Icons.storage,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatFileSize(workspace.fileSize!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWorkspaceCard(WorkspaceHistoryEntry workspace, ThemeData theme, ColorScheme colorScheme) {
    final fileExists = File(workspace.filePath).existsSync();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: fileExists ? () => widget.onRecentWorkspaceSelected?.call(workspace) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: fileExists
                        ? (workspace.fileType == 'dsl'
                            ? colorScheme.primaryContainer
                            : colorScheme.secondaryContainer)
                        : colorScheme.errorContainer,
                    child: Icon(
                      fileExists
                          ? (workspace.fileType == 'dsl' ? Icons.code : Icons.description)
                          : Icons.error,
                      color: fileExists
                          ? (workspace.fileType == 'dsl'
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSecondaryContainer)
                          : colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspace.workspaceName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: fileExists ? null : colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          workspace.filePath,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!fileExists)
                    Icon(
                      Icons.warning,
                      color: colorScheme.error,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(workspace.lastOpened),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (workspace.fileSize != null) ...[
                    Icon(
                      Icons.storage,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatFileSize(workspace.fileSize!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (!fileExists) ...[
                const SizedBox(height: 8),
                Text(
                  'File not found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateMenu(),
      icon: const Icon(Icons.add),
      label: const Text('Create'),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    );
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('New Workspace'),
              onTap: () {
                Navigator.pop(context);
                widget.onCreateNew?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import File'),
              onTap: () {
                Navigator.pop(context);
                widget.onImportFile?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleWorkspaceAction(String action, WorkspaceFileInfo workspace) {
    switch (action) {
      case 'open':
        widget.onWorkspaceSelected?.call(workspace);
        break;
      case 'details':
        _showWorkspaceDetails(workspace);
        break;
      case 'delete':
        _showDeleteConfirmation(workspace);
        break;
    }
  }

  void _showWorkspaceDetails(WorkspaceFileInfo workspace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workspace.metadata?.workspaceName ?? workspace.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('File Name', workspace.fileName),
            _buildDetailRow('Format', workspace.format.name.toUpperCase()),
            _buildDetailRow('File Size', workspace.fileSize != null ? _formatFileSize(workspace.fileSize!) : 'Unknown'),
            _buildDetailRow('Last Modified', workspace.lastModified != null ? _formatDate(workspace.lastModified!) : 'Unknown'),
            _buildDetailRow('Path', workspace.filePath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(WorkspaceFileInfo workspace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Text('Are you sure you want to delete "${workspace.metadata?.workspaceName ?? workspace.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkspace(workspace);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteWorkspace(WorkspaceFileInfo workspace) async {
    try {
      final repository = EnhancedFileWorkspaceRepository.instance;
      final success = await repository.deleteWorkspace(workspace.filePath);
      
      if (success) {
        await _loadData(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workspace deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete workspace'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting workspace: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}