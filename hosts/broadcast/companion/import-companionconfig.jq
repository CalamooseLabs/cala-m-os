# Transform a Companion v4.3 "full" .companionconfig export into SQL that
# replaces the button/connection/surface state of an existing db.sqlite,
# preserving main (userconfig, page_config_version) and cloud.
#
# db shapes (observed from a v4.3.4-created db):
#   pages:     id = page number, value = {id, name, controls: {row: {col: "bank:<cid>"}}}
#   controls:  id = "bank:<cid>", value = the control JSON (inline in the export)
#   instances: id = instance id, value = instance JSON (export: instances + surfaceInstances)
#   surfaces / surface_groups: id = key, value = JSON (verbatim from export)

def sqlstr: tojson | gsub("'"; "''") | "'" + . + "'";
def rawsql: gsub("'"; "''") | "'" + . + "'";

"BEGIN;",
"DELETE FROM pages;",
"DELETE FROM controls;",
"DELETE FROM instances;",
"DELETE FROM surfaces;",
"DELETE FROM surface_groups;",

( (.instances + .surfaceInstances) | to_entries[]
  | "INSERT INTO instances (id, value) VALUES (" + (.key|rawsql) + ", " + (.value|sqlstr) + ");"
),

( .pages | to_entries[] | .key as $pnum | .value as $page
  | ( [ $page.controls | to_entries[] | .key as $row | .value | to_entries[]
        | { row: $row, col: .key,
            id: ("bank:seed-p" + $pnum + "-r" + $row + "-c" + .key),
            ctrl: .value } ] ) as $ctrls
  | ( $ctrls[]
      | "INSERT INTO controls (id, value) VALUES (" + (.id|rawsql) + ", " + (.ctrl|sqlstr) + ");" ),
    ( { id: $page.id, name: $page.name,
        controls: ($ctrls | group_by(.row)
          | map({ key: .[0].row,
                  value: (map({key: .col, value: .id}) | from_entries) })
          | from_entries) }
      | "INSERT INTO pages (id, value) VALUES (" + ($pnum|rawsql) + ", " + (sqlstr) + ");" )
),

( .surfaces | to_entries[]
  | "INSERT INTO surfaces (id, value) VALUES (" + (.key|rawsql) + ", " + (.value|sqlstr) + ");"
),

( .surfaceGroups | to_entries[]
  | "INSERT INTO surface_groups (id, value) VALUES (" + (.key|rawsql) + ", " + (.value|sqlstr) + ");"
),
"COMMIT;"
