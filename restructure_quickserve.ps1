$ErrorActionPreference = 'Stop'
$root = 'D:\quickserve'

function Move-Rel([string]$from, [string]$to) {
  $source = Join-Path $root $from
  $destination = Join-Path $root $to
  $sourceExists = Test-Path -LiteralPath $source
  $destinationExists = Test-Path -LiteralPath $destination
  if (-not $sourceExists) {
    if (-not $destinationExists) { Write-Host "Skipping absent path: $from" }
    return
  }
  if ($destinationExists) { throw "Both source and destination exist: $from -> $to" }
  Move-Item -LiteralPath $source -Destination $destination
}

$maps = [ordered]@{
  'apps\mobile\lib\routing\app_router.dart' = 'apps\mobile\lib\config\routes\app_router.dart'
  'apps\mobile\lib\theme\app_breakpoints.dart' = 'apps\mobile\lib\config\theme\app_breakpoints.dart'
  'apps\mobile\lib\theme\app_colors.dart' = 'apps\mobile\lib\config\theme\app_colors.dart'
  'apps\mobile\lib\theme\app_durations.dart' = 'apps\mobile\lib\config\theme\app_durations.dart'
  'apps\mobile\lib\theme\app_radius.dart' = 'apps\mobile\lib\config\theme\app_radius.dart'
  'apps\mobile\lib\theme\app_shadows.dart' = 'apps\mobile\lib\config\theme\app_shadows.dart'
  'apps\mobile\lib\theme\app_spacing.dart' = 'apps\mobile\lib\config\theme\app_spacing.dart'
  'apps\mobile\lib\theme\app_theme.dart' = 'apps\mobile\lib\config\theme\app_theme.dart'
  'apps\mobile\lib\firebase\emulator_config.dart' = 'apps\mobile\lib\config\firebase\emulator_config.dart'
  'apps\mobile\lib\firebase_options.dart' = 'apps\mobile\lib\config\firebase\firebase_options.dart'
  'apps\mobile\lib\state\auth_providers.dart' = 'apps\mobile\lib\features\auth\presentation\providers\auth_providers.dart'
  'apps\mobile\lib\data\auth_repository.dart' = 'apps\mobile\lib\features\auth\data\repositories\auth_repository.dart'
  'apps\mobile\lib\data\user_repository.dart' = 'apps\mobile\lib\features\profile\data\user_repository.dart'
  'apps\mobile\lib\data\service_repository.dart' = 'apps\mobile\lib\features\services\data\repositories\service_repository.dart'
  'apps\mobile\lib\data\request_repository.dart' = 'apps\mobile\lib\features\requests\data\repositories\request_repository.dart'
  'apps\mobile\lib\data\agent_repository.dart' = 'apps\mobile\lib\features\agent\data\agent_repository.dart'
  'apps\mobile\lib\features\login_screen.dart' = 'apps\mobile\lib\features\auth\presentation\screens\login_screen.dart'
  'apps\mobile\lib\features\register_screen.dart' = 'apps\mobile\lib\features\auth\presentation\screens\register_screen.dart'
  'apps\mobile\lib\features\register_password_requirements.dart' = 'apps\mobile\lib\features\auth\presentation\widgets\register_password_requirements.dart'
  'apps\mobile\lib\features\password_reset_screen.dart' = 'apps\mobile\lib\features\auth\presentation\screens\password_reset_screen.dart'
  'apps\mobile\lib\features\splash_screen.dart' = 'apps\mobile\lib\features\auth\presentation\screens\splash_screen.dart'
  'apps\mobile\lib\features\home_screen.dart' = 'apps\mobile\lib\features\home\presentation\screens\home_screen.dart'
  'apps\mobile\lib\features\services_screen.dart' = 'apps\mobile\lib\features\services\presentation\screens\services_screen.dart'
  'apps\mobile\lib\features\create_request_screen.dart' = 'apps\mobile\lib\features\requests\presentation\screens\create_request_screen.dart'
  'apps\mobile\lib\features\my_requests_screen.dart' = 'apps\mobile\lib\features\requests\presentation\screens\my_requests_screen.dart'
  'apps\mobile\lib\features\request_details_screen.dart' = 'apps\mobile\lib\features\requests\presentation\screens\request_details_screen.dart'
  'apps\mobile\lib\features\request_success_screen.dart' = 'apps\mobile\lib\features\requests\presentation\screens\request_success_screen.dart'
  'apps\mobile\lib\features\service_details_screen.dart' = 'apps\mobile\lib\features\services\presentation\screens\service_details_screen.dart'
  'apps\mobile\lib\features\agent_requests_screen.dart' = 'apps\mobile\lib\features\agent\presentation\screens\agent_requests_screen.dart'
  'apps\mobile\lib\features\profile_screen.dart' = 'apps\mobile\lib\features\profile\presentation\screens\profile_screen.dart'
  'apps\mobile\lib\features\notifications_screen.dart' = 'apps\mobile\lib\features\profile\presentation\screens\notifications_screen.dart'
  'apps\mobile\lib\features\settings_screen.dart' = 'apps\mobile\lib\features\profile\presentation\screens\settings_screen.dart'
  'apps\mobile\lib\features\quickserve_widgets.dart' = 'apps\mobile\lib\shared\widgets\quickserve_widgets.dart'
  'apps\mobile\lib\utils\app_exceptions.dart' = 'apps\mobile\lib\core\error\app_exceptions.dart'
  'apps\mobile\lib\utils\firebase_error_mapper.dart' = 'apps\mobile\lib\core\error\firebase_error_mapper.dart'
  'apps\mobile\lib\utils\app_snackbar.dart' = 'apps\mobile\lib\core\utils\app_snackbar.dart'
  'apps\mobile\lib\utils\context_extensions.dart' = 'apps\mobile\lib\core\utils\context_extensions.dart'

  'apps\admin\lib\portal_pages.dart' = 'apps\admin\lib\config\routes\portal_pages.dart'
  'apps\admin\lib\admin_repository.dart' = 'apps\admin\lib\core\network\admin_repository.dart'
  'apps\admin\lib\admin_repository_service_extensions.dart' = 'apps\admin\lib\core\network\admin_repository_service_extensions.dart'
  'apps\admin\lib\core\admin_filters.dart' = 'apps\admin\lib\core\utils\admin_filters.dart'
  'apps\admin\lib\firebase\emulator_config.dart' = 'apps\admin\lib\config\firebase\emulator_config.dart'
  'apps\admin\lib\firebase_options.dart' = 'apps\admin\lib\config\firebase\firebase_options.dart'
  'apps\admin\lib\features\notifications\presentation\screens\notifications_screen.dart' = 'apps\admin\lib\features\activity\presentation\screens\notifications_screen.dart'

  'packages\shared\lib\src\constants.dart' = 'packages\shared\lib\constants\constants.dart'
  'packages\shared\lib\src\enums.dart' = 'packages\shared\lib\constants\enums.dart'
  'packages\shared\lib\src\errors.dart' = 'packages\shared\lib\utils\errors.dart'
  'packages\shared\lib\src\lifecycle.dart' = 'packages\shared\lib\utils\lifecycle.dart'
  'packages\shared\lib\src\request_code.dart' = 'packages\shared\lib\utils\request_code.dart'
  'packages\shared\lib\src\validators.dart' = 'packages\shared\lib\validators\validators.dart'
  'packages\shared\lib\src\models\audit_log.dart' = 'packages\shared\lib\models\audit_log.dart'
  'packages\shared\lib\src\models\counter.dart' = 'packages\shared\lib\models\counter.dart'
  'packages\shared\lib\src\models\request.dart' = 'packages\shared\lib\models\request.dart'
  'packages\shared\lib\src\models\service.dart' = 'packages\shared\lib\models\service.dart'
  'packages\shared\lib\src\models\status_history.dart' = 'packages\shared\lib\models\status_history.dart'
  'packages\shared\lib\src\models\user.dart' = 'packages\shared\lib\models\user.dart'
  'packages\shared\lib\src\models\model_helpers.dart' = 'packages\shared\lib\utils\model_helpers.dart'

  'firestore.rules' = 'firebase\firestore\rules\firestore.rules'
  'firestore.indexes.json' = 'firebase\firestore\indexes\firestore.indexes.json'
}

$extraDirs = @(
  'apps\mobile\lib\config\routes', 'apps\mobile\lib\config\theme', 'apps\mobile\lib\config\firebase',
  'apps\mobile\lib\core\constants', 'apps\mobile\lib\core\error', 'apps\mobile\lib\core\network', 'apps\mobile\lib\core\utils', 'apps\mobile\lib\core\validators',
  'apps\mobile\lib\shared\providers', 'apps\mobile\lib\shared\widgets', 'apps\mobile\lib\shared\components',
  'apps\mobile\lib\features\auth\data\data_sources', 'apps\mobile\lib\features\auth\data\models', 'apps\mobile\lib\features\auth\data\repositories',
  'apps\mobile\lib\features\auth\domain\entities', 'apps\mobile\lib\features\auth\domain\repositories', 'apps\mobile\lib\features\auth\domain\usecases',
  'apps\mobile\lib\features\auth\presentation\providers', 'apps\mobile\lib\features\auth\presentation\screens', 'apps\mobile\lib\features\auth\presentation\widgets',
  'apps\mobile\lib\features\home\presentation\providers', 'apps\mobile\lib\features\home\presentation\screens', 'apps\mobile\lib\features\home\presentation\widgets',
  'apps\mobile\lib\features\services\data\data_sources', 'apps\mobile\lib\features\services\data\models', 'apps\mobile\lib\features\services\data\repositories',
  'apps\mobile\lib\features\services\domain\entities', 'apps\mobile\lib\features\services\domain\repositories', 'apps\mobile\lib\features\services\domain\usecases',
  'apps\mobile\lib\features\services\presentation\providers', 'apps\mobile\lib\features\services\presentation\screens', 'apps\mobile\lib\features\services\presentation\widgets',
  'apps\mobile\lib\features\requests\data\data_sources', 'apps\mobile\lib\features\requests\data\models', 'apps\mobile\lib\features\requests\data\repositories',
  'apps\mobile\lib\features\requests\domain\entities', 'apps\mobile\lib\features\requests\domain\repositories', 'apps\mobile\lib\features\requests\domain\usecases',
  'apps\mobile\lib\features\requests\presentation\providers', 'apps\mobile\lib\features\requests\presentation\screens', 'apps\mobile\lib\features\requests\presentation\widgets',
  'apps\mobile\lib\features\profile\data', 'apps\mobile\lib\features\profile\domain', 'apps\mobile\lib\features\profile\presentation\providers', 'apps\mobile\lib\features\profile\presentation\screens', 'apps\mobile\lib\features\profile\presentation\widgets',
  'apps\mobile\lib\features\agent\data', 'apps\mobile\lib\features\agent\domain', 'apps\mobile\lib\features\agent\presentation\providers', 'apps\mobile\lib\features\agent\presentation\screens', 'apps\mobile\lib\features\agent\presentation\widgets',
  'apps\admin\lib\config', 'apps\admin\lib\config\routes', 'apps\admin\lib\config\theme', 'apps\admin\lib\config\firebase',
  'apps\admin\lib\core', 'apps\admin\lib\core\error', 'apps\admin\lib\core\network', 'apps\admin\lib\core\utils', 'apps\admin\lib\core\validators',
  'apps\admin\lib\shared', 'apps\admin\lib\shared\widgets', 'apps\admin\lib\shared\components',
  'apps\admin\lib\features\auth', 'apps\admin\lib\features\dashboard', 'apps\admin\lib\features\requests', 'apps\admin\lib\features\customers', 'apps\admin\lib\features\agents', 'apps\admin\lib\features\services', 'apps\admin\lib\features\activity', 'apps\admin\lib\features\settings',
  'packages\shared\lib\constants', 'packages\shared\lib\models', 'packages\shared\lib\validators', 'packages\shared\lib\utils',
  'firebase\firestore\rules', 'firebase\firestore\indexes', 'firebase\functions'
)
foreach ($dir in $extraDirs) { New-Item -ItemType Directory -Force -Path (Join-Path $root $dir) | Out-Null }

foreach ($entry in $maps.GetEnumerator()) { Move-Rel $entry.Key $entry.Value }

function Rewrite-File([string]$relativePath, [hashtable]$replacements) {
  $path = Join-Path $root $relativePath
  $text = [System.IO.File]::ReadAllText($path)
  foreach ($replacement in $replacements.GetEnumerator()) {
    $text = $text.Replace($replacement.Key, $replacement.Value)
  }
  [System.IO.File]::WriteAllText($path, $text)
}

$mobileReplacements = @{
  "'routing/app_router.dart'" = "'package:quickserve_mobile/config/routes/app_router.dart'"
  "'../state/auth_providers.dart'" = "'package:quickserve_mobile/features/auth/presentation/providers/auth_providers.dart'"
  "'../data/auth_repository.dart'" = "'package:quickserve_mobile/features/auth/data/repositories/auth_repository.dart'"
  "'../data/user_repository.dart'" = "'package:quickserve_mobile/features/profile/data/user_repository.dart'"
  "'../data/service_repository.dart'" = "'package:quickserve_mobile/features/services/data/repositories/service_repository.dart'"
  "'../data/request_repository.dart'" = "'package:quickserve_mobile/features/requests/data/repositories/request_repository.dart'"
  "'../data/agent_repository.dart'" = "'package:quickserve_mobile/features/agent/data/agent_repository.dart'"
  "'theme/" = "'package:quickserve_mobile/config/theme/"
  "'../theme/" = "'package:quickserve_mobile/config/theme/"
  "'firebase/" = "'package:quickserve_mobile/config/firebase/"
  "'firebase_options.dart'" = "'package:quickserve_mobile/config/firebase/firebase_options.dart'"
  "'../utils/app_exceptions.dart'" = "'package:quickserve_mobile/core/error/app_exceptions.dart'"
  "'../utils/firebase_error_mapper.dart'" = "'package:quickserve_mobile/core/error/firebase_error_mapper.dart'"
  "'../utils/app_snackbar.dart'" = "'package:quickserve_mobile/core/utils/app_snackbar.dart'"
  "'../utils/context_extensions.dart'" = "'package:quickserve_mobile/core/utils/context_extensions.dart'"
  "'app_exceptions.dart'" = "'package:quickserve_mobile/core/error/app_exceptions.dart'"
  "'register_password_requirements.dart'" = "'package:quickserve_mobile/features/auth/presentation/widgets/register_password_requirements.dart'"
  "'../features/agent_requests_screen.dart'" = "'package:quickserve_mobile/features/agent/presentation/screens/agent_requests_screen.dart'"
  "'../features/create_request_screen.dart'" = "'package:quickserve_mobile/features/requests/presentation/screens/create_request_screen.dart'"
  "'../features/home_screen.dart'" = "'package:quickserve_mobile/features/home/presentation/screens/home_screen.dart'"
  "'../features/login_screen.dart'" = "'package:quickserve_mobile/features/auth/presentation/screens/login_screen.dart'"
  "'../features/my_requests_screen.dart'" = "'package:quickserve_mobile/features/requests/presentation/screens/my_requests_screen.dart'"
  "'../features/request_details_screen.dart'" = "'package:quickserve_mobile/features/requests/presentation/screens/request_details_screen.dart'"
  "'../features/request_success_screen.dart'" = "'package:quickserve_mobile/features/requests/presentation/screens/request_success_screen.dart'"
  "'../features/service_details_screen.dart'" = "'package:quickserve_mobile/features/services/presentation/screens/service_details_screen.dart'"
  "'../features/services_screen.dart'" = "'package:quickserve_mobile/features/services/presentation/screens/services_screen.dart'"
  "'../features/profile_screen.dart'" = "'package:quickserve_mobile/features/profile/presentation/screens/profile_screen.dart'"
  "'../features/notifications_screen.dart'" = "'package:quickserve_mobile/features/profile/presentation/screens/notifications_screen.dart'"
  "'../features/settings_screen.dart'" = "'package:quickserve_mobile/features/profile/presentation/screens/settings_screen.dart'"
  "'../features/quickserve_widgets.dart'" = "'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart'"
  "'quickserve_widgets.dart'" = "'package:quickserve_mobile/shared/widgets/quickserve_widgets.dart'"
  "'../features/password_reset_screen.dart'" = "'package:quickserve_mobile/features/auth/presentation/screens/password_reset_screen.dart'"
  "'../features/register_screen.dart'" = "'package:quickserve_mobile/features/auth/presentation/screens/register_screen.dart'"
  "'../features/splash_screen.dart'" = "'package:quickserve_mobile/features/auth/presentation/screens/splash_screen.dart'"
}
Get-ChildItem -LiteralPath (Join-Path $root 'apps\mobile\lib') -Recurse -File -Filter *.dart | ForEach-Object {
  Rewrite-File $_.FullName.Substring($root.Length + 1) $mobileReplacements
}

$adminReplacements = @{
  "'admin_repository.dart'" = "'package:quickserve_admin/core/network/admin_repository.dart'"
  "'../../../admin_repository.dart'" = "'package:quickserve_admin/core/network/admin_repository.dart'"
  "'../../../../admin_repository.dart'" = "'package:quickserve_admin/core/network/admin_repository.dart'"
  "'../../../../admin_repository_service_extensions.dart'" = "'package:quickserve_admin/core/network/admin_repository_service_extensions.dart'"
  "'../../../../shared/admin_formatters.dart'" = "'package:quickserve_admin/shared/admin_formatters.dart'"
  "'../../../../core/admin_filters.dart'" = "'package:quickserve_admin/core/utils/admin_filters.dart'"
  "'portal_pages.dart'" = "'package:quickserve_admin/config/routes/portal_pages.dart'"
  "'features/notifications/presentation/screens/notifications_screen.dart'" = "'features/activity/presentation/screens/notifications_screen.dart'"
  "'firebase/" = "'package:quickserve_admin/config/firebase/"
  "'firebase_options.dart'" = "'package:quickserve_admin/config/firebase/firebase_options.dart'"
}
Get-ChildItem -LiteralPath (Join-Path $root 'apps\admin\lib') -Recurse -File -Filter *.dart | ForEach-Object {
  Rewrite-File $_.FullName.Substring($root.Length + 1) $adminReplacements
}

$sharedReplacements = @{
  "'constants.dart'" = "'package:shared/constants/constants.dart'"
  "'../constants.dart'" = "'package:shared/constants/constants.dart'"
  "'errors.dart'" = "'package:shared/utils/errors.dart'"
  "'model_helpers.dart'" = "'package:shared/utils/model_helpers.dart'"
  "'../enums.dart'" = "'package:shared/constants/enums.dart'"
  "'../errors.dart'" = "'package:shared/utils/errors.dart'"
}
Get-ChildItem -LiteralPath (Join-Path $root 'packages\shared\lib') -Recurse -File -Filter *.dart | ForEach-Object {
  Rewrite-File $_.FullName.Substring($root.Length + 1) $sharedReplacements
}

$sharedExports = @"
export 'constants/constants.dart';
export 'constants/enums.dart';
export 'utils/errors.dart';
export 'utils/lifecycle.dart';
export 'utils/request_code.dart';
export 'validators/validators.dart';
export 'models/audit_log.dart';
export 'models/counter.dart';
export 'models/request.dart';
export 'models/service.dart';
export 'models/status_history.dart';
export 'models/user.dart';
"@
[System.IO.File]::WriteAllText((Join-Path $root 'packages\shared\lib\shared.dart'), $sharedExports.TrimStart())

$firebaseJsonPath = Join-Path $root 'firebase.json'
$firebaseJson = [System.IO.File]::ReadAllText($firebaseJsonPath)
$firebaseJson = $firebaseJson.Replace('"rules": "firestore.rules"', '"rules": "firebase/firestore/rules/firestore.rules"')
$firebaseJson = $firebaseJson.Replace('"indexes": "firestore.indexes.json"', '"indexes": "firebase/firestore/indexes/firestore.indexes.json"')
[System.IO.File]::WriteAllText($firebaseJsonPath, $firebaseJson)

# Update tests that referenced the old mobile utility paths.
$testPath = Join-Path $root 'apps\mobile\test\firebase_error_mapper_test.dart'
if (Test-Path -LiteralPath $testPath) {
  Rewrite-File 'apps\mobile\test\firebase_error_mapper_test.dart' @{
    "package:quickserve_mobile/utils/app_exceptions.dart" = 'package:quickserve_mobile/core/error/app_exceptions.dart'
    "package:quickserve_mobile/utils/firebase_error_mapper.dart" = 'package:quickserve_mobile/core/error/firebase_error_mapper.dart'
  }
}

# Remove only empty legacy directories.
$legacy = @(
  'apps\mobile\lib\routing','apps\mobile\lib\theme','apps\mobile\lib\firebase','apps\mobile\lib\state','apps\mobile\lib\data','apps\mobile\lib\utils',
  'apps\admin\lib\firebase','apps\admin\lib\features\notifications','packages\shared\lib\src'
)
foreach ($relative in $legacy) {
  $path = Join-Path $root $relative
  if (Test-Path -LiteralPath $path) {
    $items = Get-ChildItem -LiteralPath $path -Force
    if ($items.Count -eq 0) { Remove-Item -LiteralPath $path -Force }
  }
}

Write-Host "QuickServe architecture migration completed."
Write-Host "No business logic was changed. Run the verification commands next."
