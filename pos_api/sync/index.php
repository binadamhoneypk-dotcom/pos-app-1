<?php
// Matches lib/core/services/api_client.dart exactly:
//   GET  /sync/{table}?since={epochMillis}&business_uuid=...
//   POST /sync/{table}   body: { "rows": [ {...}, {...} ] }
//
// SECURITY NOTE: this Phase 1 stub has no auth token check yet. Before
// going live, require the session token (see AppConstants.prefSessionTokenKey
// on the Flutter side) in an Authorization header and validate it here,
// and scope every query to businesses the token's user actually belongs to.

header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/../config/db.php';

// Only these tables may be synced — never trust the table name from the
// URL directly, or this becomes an arbitrary-table SQL injection vector.
// Phase 2 added items/customers/sales/sale_items; Phase 3 adds
// ledger_entries/employees/employee_transactions/attendance — matching
// lib/core/services/sync_service.dart's syncableTables exactly.
$ALLOWED_TABLES = [
    'users', 'businesses', 'business_users',
    'items', 'customers', 'sales', 'sale_items',
    'ledger_entries', 'employees', 'employee_transactions', 'attendance',
];

$table = $_GET['table'] ?? '';
if (!in_array($table, $ALLOWED_TABLES, true)) {
    http_response_code(400);
    echo json_encode(['error' => 'Unknown or disallowed table']);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    pullChanges($pdo, $table);
} elseif ($method === 'POST') {
    pushChanges($pdo, $table);
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}

function pullChanges(PDO $pdo, string $table): void
{
    $since = isset($_GET['since']) ? (int)$_GET['since'] : 0;

    $sql = "SELECT * FROM `$table` WHERE last_updated > :since";
    $params = ['since' => $since];

    // business_uuid filter, when provided, scopes results to one shop so a
    // staff device only ever pulls data for the business it's logged into.
    if (!empty($_GET['business_uuid']) && $table !== 'users') {
        $col = $table === 'businesses' ? 'uuid' : 'business_uuid';
        $sql .= " AND `$col` = :business_uuid";
        $params['business_uuid'] = $_GET['business_uuid'];
    }

    $sql .= ' ORDER BY last_updated ASC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
}

function pushChanges(PDO $pdo, string $table): void
{
    $body = json_decode(file_get_contents('php://input'), true);
    $rows = $body['rows'] ?? [];

    if (!is_array($rows) || count($rows) === 0) {
        echo json_encode(['upserted' => 0]);
        return;
    }

    $columns = array_keys($rows[0]);
    $columnList = implode(', ', array_map(fn($c) => "`$c`", $columns));
    $placeholders = implode(', ', array_map(fn($c) => ":$c", $columns));
    // Conflict policy: last-write-wins by last_updated. Upsert unconditionally
    // here; if you want stricter conflict handling, add a WHERE
    // last_updated < VALUES(last_updated) guard per column.
    $updateList = implode(', ', array_map(fn($c) => "`$c` = VALUES(`$c`)", $columns));

    $sql = "INSERT INTO `$table` ($columnList) VALUES ($placeholders)
            ON DUPLICATE KEY UPDATE $updateList";
    $stmt = $pdo->prepare($sql);

    $pdo->beginTransaction();
    try {
        foreach ($rows as $row) {
            $stmt->execute($row);
        }
        $pdo->commit();
    } catch (Exception $e) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Push failed', 'detail' => $e->getMessage()]);
        return;
    }

    echo json_encode(['upserted' => count($rows)]);
}
