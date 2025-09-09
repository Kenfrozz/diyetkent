import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

// Tables
import 'tables/chats_table.dart';
import 'tables/messages_table.dart';
import 'tables/users_table.dart';
import 'tables/groups_table.dart';
import 'tables/stories_table.dart';
import 'tables/tags_table.dart';
import 'tables/contact_indexes_table.dart';
import 'tables/pre_consultation_forms_table.dart';
import 'tables/call_logs_table.dart';
import 'tables/health_data_table.dart';
import 'tables/diet_files_table.dart';
import 'tables/user_roles_table.dart';
import 'tables/diet_packages_table.dart';
import 'tables/user_diet_assignments_table.dart';
import 'tables/meal_reminder_preferences_table.dart';
import 'tables/meal_reminder_behaviors_table.dart';
import 'tables/progress_reminders_table.dart';

// DAOs
import 'daos/chat_dao.dart';
import 'daos/message_dao.dart';
import 'daos/user_dao.dart';
import 'daos/group_dao.dart';
import 'daos/story_dao.dart';
import 'daos/tag_dao.dart';
import 'daos/contact_index_dao.dart';
import 'daos/pre_consultation_form_dao.dart';
import 'daos/call_log_dao.dart';
import 'daos/health_data_dao.dart';
import 'daos/diet_file_dao.dart';
import 'daos/user_role_dao.dart';
import 'daos/diet_package_dao.dart';
import 'daos/user_diet_assignment_dao.dart';
import 'daos/meal_reminder_dao.dart';
import 'daos/progress_reminder_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Chats,
    Messages,
    UsersTable,
    GroupsTable,
    GroupMembersTable,
    StoriesTable,
    TagsTable,
    ContactIndexesTable,
    PreConsultationFormsTable,
    CallLogsTable,
    HealthDataTable,
    DietFilesTable,
    UserRolesTable,
    DietPackagesTable,
    UserDietAssignmentsTable,
    MealReminderPreferencesTable,
    MealReminderBehaviorsTable,
    UserBehaviorAnalyticsTable,
    ProgressRemindersTable,
  ],
  daos: [
    ChatDao,
    MessageDao,
    UserDao,
    GroupDao,
    StoryDao,
    TagDao,
    ContactIndexDao,
    PreConsultationFormDao,
    CallLogDao,
    HealthDataDao,
    DietFileDao,
    UserRoleDao,
    DietPackageDao,
    UserDietAssignmentDao,
    MealReminderDao,
    ProgressReminderDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations here
      },
    );
  }

  // Helper method to clear all data (for logout)
  Future<void> clearAll() async {
    await batch((batch) {
      for (final table in allTables) {
        batch.deleteWhere(table, (tbl) => const Constant(true));
      }
    });
  }

  // Singleton pattern for database access
  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'diyetkent.db'));

    // Also work around limitations on old Android versions
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // Make sqlite3 pick a more suitable location for temporary files - the
    // one from the system may be inaccessible due to sandboxing.
    final cachebase = (await getTemporaryDirectory()).path;
    // We can't access /tmp on Android, which sqlite3 would try by default.
    // Explicitly tell it about the correct temporary directory.
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}