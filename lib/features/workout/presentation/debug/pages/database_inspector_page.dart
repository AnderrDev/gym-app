import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/database/database_helper.dart';
import 'package:gym_flutter/injection_container.dart';

class DatabaseInspectorPage extends StatefulWidget {
  const DatabaseInspectorPage({super.key});

  @override
  State<DatabaseInspectorPage> createState() => _DatabaseInspectorPageState();
}

class _DatabaseInspectorPageState extends State<DatabaseInspectorPage> {
  List<Map<String, dynamic>> _workoutsLocal = [];
  List<Map<String, dynamic>> _setLogsLocal = [];
  List<Map<String, dynamic>> _workoutsRemote = [];
  List<Map<String, dynamic>> _setLogsRemote = [];
  String _authCache = "Cargando...";
  String _errorMessage = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final db = DatabaseHelper.instance;
      final prefs = sl<SharedPreferences>();
      final supabase = sl<SupabaseClient>();

      // 1. Cargar Auth Cache de inmediato (Es lo más rápido)
      final cachedUser =
          prefs.getString('CACHED_USER') ?? "No hay usuario en caché";
      setState(() {
        _authCache = cachedUser;
      });

      // 2. Cargar Datos Locales y Remotos en paralelo
      await Future.wait([
        // Locales
        db.getAllRows('workouts').then((data) {
          if (!mounted) return;
          setState(() {
            _workoutsLocal = data;
          });
        }),
        db.getAllRows('set_logs').then((data) {
          if (!mounted) return;
          setState(() {
            _setLogsLocal = data;
          });
        }),

        // Remotos (con manejo de error individual para no romper lo local)
        supabase
            .from('workouts')
            .select()
            .order('started_at', ascending: false)
            .limit(20)
            .then((data) {
              if (!mounted) return;
              setState(() {
                _workoutsRemote = List<Map<String, dynamic>>.from(data as List);
              });
            })
            .catchError((e) => null),

        supabase
            .from('set_logs')
            .select()
            .order('created_at', ascending: false)
            .limit(20)
            .then((data) {
              if (!mounted) return;
              setState(() {
                _setLogsRemote = List<Map<String, dynamic>>.from(data as List);
              });
            })
            .catchError((e) => null),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error al refrescar algunos datos: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearDB() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('¿Limpiar Base de Datos?', style: AppTextStyles.bodyLarge),
        content: const Text(
          'Esto borrará todos los entrenamientos y logs locales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Borrar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.clearDatabase();
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text('DB Inspector', style: AppTextStyles.heading2),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.error),
              onPressed: _clearDB,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textDisabled,
            tabs: [
              Tab(text: 'Workouts (L)'),
              Tab(text: 'Logs (L)'),
              Tab(text: 'Workouts (R)'),
              Tab(text: 'Logs (R)'),
              Tab(text: 'Auth Cache'),
            ],
          ),
        ),
        body: _errorMessage.isNotEmpty
            ? _buildErrorView()
            : TabBarView(
                children: [
                  _buildWorkoutsTable(_workoutsLocal, isRemote: false),
                  _buildSetLogsTable(_setLogsLocal, isRemote: false),
                  _buildWorkoutsTable(_workoutsRemote, isRemote: true),
                  _buildSetLogsTable(_setLogsRemote, isRemote: true),
                  _buildAuthInfo(),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsTable(
    List<Map<String, dynamic>> data, {
    required bool isRemote,
  }) {
    if (data.isEmpty) return _buildEmpty();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Started At')),
            DataColumn(label: Text('Sync?')),
          ],
          rows: data
              .map(
                (w) => DataRow(
                  cells: [
                    DataCell(Text(w['id'].toString().substring(0, 8))),
                    DataCell(Text(w['user_id'].toString().substring(0, 8))),
                    DataCell(Text(w['started_at'].toString().substring(5, 16))),
                    DataCell(
                      isRemote
                          ? const Icon(
                              Icons.cloud_done,
                              color: AppColors.primary,
                              size: 18,
                            )
                          : _buildStatusIcon(w['is_synced']),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSetLogsTable(
    List<Map<String, dynamic>> data, {
    required bool isRemote,
  }) {
    if (data.isEmpty) return _buildEmpty();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Weight')),
            DataColumn(label: Text('Reps')),
            DataColumn(label: Text('Created At')),
            DataColumn(label: Text('Sync?')),
          ],
          rows: data
              .map(
                (l) => DataRow(
                  cells: [
                    DataCell(Text('${l['actual_weight']} lbs')),
                    DataCell(Text('${l['actual_reps']}')),
                    DataCell(Text(l['created_at'].toString().substring(5, 16))),
                    DataCell(
                      isRemote
                          ? const Icon(
                              Icons.cloud_done,
                              color: AppColors.primary,
                              size: 18,
                            )
                          : _buildStatusIcon(l['is_synced']),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAuthInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SharedPreferences: CACHED_USER',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _authCache,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(dynamic isSynced) {
    bool synced = isSynced == 1;
    return Icon(
      synced ? Icons.cloud_done : Icons.cloud_off,
      color: synced ? AppColors.primary : AppColors.error,
      size: 18,
    );
  }

  Widget _buildEmpty() =>
      const Center(child: Text('No hay datos en esta tabla'));
}
