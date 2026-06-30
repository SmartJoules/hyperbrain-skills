---
name: cpa-rca
description: Investigate CPA (Chiller Plant Automation) issues at any SmartJoules site. Takes a complaint and produces a structured RCA report.
origin: DeJoule
---

# CPA RCA Generator

Investigate CPA (Chiller Plant Automation) issues at any SmartJoules site.

Takes a natural language complaint and produces a structured RCA report using all available data sources.

## Trigger

User says anything like:
- "investigate {site} ..."
- "RCA for {site} ..."
- "why is {issue} at {site}?"
- "/cpa-rca {description}"
- Pastes a support ticket / Slack message about a CPA issue

## Input Parsing

Extract from the user's message:
- **site_id**: Map hospital names to site IDs (Apollo=aph-*, Aster=ash-*, KIMS=khh-*/kims, Sunshine=suh-*, Apollo Cradle=acc-*, Aster MIMS Calicut=amh-cal, etc.)
- **issue_type**: CT not starting, frequency stuck, setpoint wrong, high kW, safety net failing, commands failing, optimization not running, asset selection wrong, chiller boot stuck, TI oscillating
- **time_range**: When did the issue occur? Default to last 6 hours if not specified
- **specific_assets**: Any specific equipment mentioned (CT2 Fan 2, Chiller 1, etc.)

If site_id is unclear, search Neo4j:
```cypher
MATCH (s:Site) WHERE toLower(s.siteName) CONTAINS '{keyword}' OR s.siteId CONTAINS '{keyword}' RETURN s.siteId
```

## Investigation Sequence

Execute these steps IN ORDER. Each step informs the next.

### Step 0: Sync Neo4j (MANDATORY before Step 1)

Neo4j may be stale. ALWAYS sync the site's profiles before querying:

```bash
# 1. Ensure Neo4j is running
docker ps | grep neo4j || echo "START NEO4J FIRST: docker start talk-to-building-neo4j"

# 2. Run sync script (requires AWS creds — ask user if not in env)
python3 /Users/sakshamdutta/scripts/sync_profiles_to_neo4j.py --sites {site_id}
```

The sync script downloads `profiles.yaml` from S3 (`cpa-conf-bucket/{site_id}/profiles.yaml`) and creates Neo4j Profile nodes. It needs AWS credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_DEFAULT_REGION=ap-south-1`).

**If AWS creds are not set**: Ask the user to provide them. They expire frequently (STS tokens).

### Step 1: Site Context (Neo4j — local)

Run locally via Python:
```python
from neo4j import GraphDatabase
d = GraphDatabase.driver('bolt://localhost:7687', auth=('neo4j', 'buildingpassword'))
```

Query the CURRENT profile for the relevant time:
```cypher
MATCH (c:Component {siteId: $site})-[:HAS_PROFILE]->(p:Profile)
WHERE c.yamlDeviceType IN ['chiller', 'coolingTower', 'condenserWaterPump', 'primaryChilledWaterPump']
AND p.day = $day AND p.startTime <= $time AND p.endTime > $time
RETURN c.componentId, c.assetName, c.yamlDeviceType,
       p.intendedState, p.modulateEnabled, p.optimizationEnabled,
       p.optimizationLogic, p.sampleTime, p.observable, p.target,
       p.rangeMin, p.rangeMax, p.operatingMin, p.operatingMax,
       p.emergencyValue, p.safetyNetEnabled, p.safetyExpression, p.safetyValue
ORDER BY c.yamlDeviceType, c.componentId
```

Also get topology:
```cypher
MATCH (c1:Component {siteId: $site})-[:FEEDS]->(c2:Component)
RETURN c1.assetName, c1.yamlDeviceType, c2.assetName, c2.yamlDeviceType
```

**Purpose**: Know what SHOULD be running, what optimization/selection algorithms are configured, what safety nets exist.

**Key**: The `optimizationLogic` field tells you WHICH algorithm is running. Cross-reference with the Algorithm Reference below.

**CRITICAL — Profile Architecture (`@all` vs individual)**:

CPA has TWO levels of profiles in `profiles.yaml`. Which one matters depends on whether **asset selection is enabled** for that asset type:

| Asset selection enabled? | `@all` profile exists? | What to check |
|---|---|---|
| **YES** (`start_action.optimization.is_enabled: true`) | YES | `@all` has start/stop selection config (algorithm, min_asset, ranges) AND modulate config (target, operating range, RL logic). The `@all` modulate config is what drives RL for that asset type's time slot. |
| **NO** (`start_action.optimization.is_enabled: false`) | NO or empty | Only **individual profiles** exist (e.g., `coolingTower@iah-del_170@Monday_0:00_23:59`). Modulation target, operatingMin/Max, RL logic come from HERE. |

**How to check**: Look at the `@all` profile's `start_action.optimization.is_enabled`:
- If `true` → `@all` profile controls BOTH asset selection AND modulation config for that time slot
- If `false` → individual profiles control modulation, no asset selection happening

In `config_manager.py`:
```python
if asset_state_list[index].startswith(f"{asset_type}@all"):
    self.__asset_selection_profiles[asset_type] = all_states.get(...)  # selection + modulate context
else:
    self.__user_intended_plant_state[asset_type][index] = all_states.get(...)  # individual modulation
```

**Common trap**: When asset selection IS enabled, the `@all` profile has the correct modulate config (e.g., target=4, ranges for night). But individual profiles may ALSO exist with DIFFERENT values (e.g., target=2, single 00:00-23:59 slot). The individual profiles' modulate config is what the RL actually uses for frequency control, while `@all`'s modulate config is used by the asset selection manager. ALWAYS check BOTH levels and compare.

**To verify from S3 directly**:
```python
import boto3, yaml
s3 = boto3.client('s3')
obj = s3.get_object(Bucket='cpa-conf-bucket', Key='{site}/profiles.yaml')
data = yaml.safe_load(obj['Body'].read())
# Check @all vs individual for the asset type in question
# @all profiles: coolingTower@all@Monday_0:00_8:00
# Individual profiles: coolingTower@iah-del_170@Monday_0:00_23:59
```

### Step 2: RL Decisions (InfluxDB — asset_optimize)

Use `mcp__morpheus__query_metrics`:
```
bucket: cpa_logs_30_days
measurement: asset_optimize
site_id: {site}
time_range: {issue_time_range}
```

**Full schema** (tags: id, site_id, observable_name, asset_name, action_name, controllerid, controllertype):

| Field | Type | Meaning |
|-------|------|---------|
| `setpoint` | float | RL's target for the OBSERVABLE (NOT Hz, NOT equipment setpoint). For CTs = condenser water temp target. For chillers = chilled water temp target. |
| `obs_before_state` | float | Observable sensor value BEFORE this optimization cycle |
| `obs_after_state` | float | Observable sensor value AFTER this optimization cycle |
| `action_before_state` | float | Equipment action value BEFORE optimization (Hz for VFDs, °C for setpoints) |
| `action_after_state` | float | Equipment action value AFTER optimization (the computed command) |
| `previous_action` | float | Previous action from rewards history |
| `raw_previous_action` | float | Raw previous action without post-processing |

**`action_name` values**: `outputfrequency` (VFD speed), `changesetpoint` (chiller CHW setpoint), `setfrequency` (pump frequency)

**`observable_name` values**: `coolewt` (chilled water leaving temp), `condewt` (condenser water entering temp), `chlwtdelta` (chilled water delta-T), `condtdelta` (condenser delta-T)

**What to look for:**
- Is `obs_before` consistently above/below `setpoint`? → Explains why RL keeps frequency high/low
- Is `action_before` == `action_after`? → Equipment not responding OR RL range locked (operatingMin==operatingMax) OR target_achieved
- Is `setpoint` stuck at one value? → Check if operating range is locked, or optimization disabled
- No records at all? → Optimization not running (check profile, check `rl_failed`, check Loki)

### Step 3: Events & Anomalies (InfluxDB — asset_event)

Use `mcp__morpheus__query_metrics`:
```
bucket: cpa_logs_30_days
measurement: asset_event
site_id: {site}
asset_id: {specific_asset if known}
time_range: {issue_time_range}
```

**Full schema** (tags: id, site_id, event_type, asset_name, param_name, controllerid, controllertype):

| Field | Type | Meaning |
|-------|------|---------|
| `UUID` | string | Unique command/event identifier (links to command_feedback) |
| `suggested_value` | float | Value CPA wants to set (the equilibrium value) |
| `present_value` | float | Current observed value of the parameter |
| `recommended_value` | float/null | DL recommendation value (when recommendations_enabled=true) |
| `event_id` | int | Numeric mapping of event_type |
| `dof` | float | Degrees of freedom — range flexibility of the action |
| `command_availability` | int (0/1) | Whether command dispatch is enabled |

**Complete event_type reference** (from `configuration/software-conf.yml`):

| event_type | event_id | Severity | What it means |
|------------|----------|----------|---------------|
| `sys_state` | 0 | INFO | Records current system state (ON/OFF/UNKNOWN). Normal bookkeeping. |
| `condition_not_met` | 1 | NORMAL | **Most common event. NOT a failure.** Default event when `raise_event()` fires. Triggers command generation. |
| `data_not_available` | 2 | **PROBLEM** | Sensor data missing — RL paused for this asset. |
| `emergency_mode_central` | 3 | **CRITICAL** | Central controller emergency fallback. |
| `emergency_mode_edge` | 4 | **CRITICAL** | Edge connectivity lost — using emergency values. |
| `profile_switch` | 5 | INFO | Scheduled profile transition. |
| `insufficient_flow` | 6 | **PROBLEM** | Flow-based protection triggered. |
| `rl_optimize` | 7 | NORMAL | RL computed an action (SingleObjective/MultiObjective/QBased). |
| `ti_optimize` | 8 | NORMAL | Tonnage Injection state machine acted. |
| `oa_optimize` | 9 | NORMAL | OAT-based optimization acted. |
| `safety_net` | 10 | **ACTION** | Safety net override forced asset state. |
| `rl_fail_safe` | 11 | **PROBLEM** | RL fell back to proportional correction (observable outside bounds). |
| `flow_based_frequency` | 12 | NORMAL | Design flow pump selector set frequency. |
| `asl_forecast_dl` | 13 | NORMAL | DL forecast control set action. |
| `q_rl_lookup_optimize` | 14 | NORMAL | Q-RL with lookup table set action. |

### Step 4: Command Execution (InfluxDB — command_feedback)

Use `mcp__morpheus__query_metrics`:
```
bucket: cpa_logs_30_days
measurement: command_feedback
site_id: {site}
time_range: {issue_time_range}
```

**Full schema** (tags: id, site_id, asset_name, param_name):

| Field | Type | Meaning |
|-------|------|---------|
| `UUID` | string | Links to asset_event UUID — trace end-to-end |
| `action_value` | float | Value that was commanded |
| `action_status` | int | Feedback status code |

**Complete status code reference:**

| Code | Meaning | CPA grouping | Alert |
|------|---------|--------------|-------|
| `-1` | Timeout — no response | **TIMEOUT** | — |
| `0` | Failed after verification | **FAILURE** | `UNABLE_TO_*` OCCURRED |
| `1` | Successfully executed | **SUCCESS** | Alert RESOLVED |
| `2` | Reached controller | IN-PROGRESS | Waiting |
| `3` | Processing error | **FAILURE** | `UNABLE_TO_*` OCCURRED |
| `4` | Same command already executing | **SUCCESS** | Idempotent, RESOLVED |
| `6` | Unable to evaluate feedback | **FAILURE** | `UNABLE_TO_*` OCCURRED |
| `7` | Reached gateway | IN-PROGRESS | Timeout if expires |
| `8` | Mode mismatch (not recipe mode) | **MODE MISMATCH** | `ASSET_NOT_IN_RECIPE_MODE` |
| `9`-`20` | Various failures | FAILURE | — |
| `17`, `18` | Command originated/executed | SUCCESS | — |

**CPA groups** (`command_feedback.py` line ~260): Success=`[1,4]`, Failure=`[0,3,6]`, Mode mismatch=`8`, Timeout=`7`

### Step 5: RL Decision Details (InfluxDB — q_rl_actions_explained)

Query when investigating WHY the RL made a specific decision:
```
bucket: cpa_logs_30_days
measurement: q_rl_actions_explained
site_id: {site}
asset_id: {asset}
```

| Field | Meaning |
|-------|---------|
| `op_mode` | **-1**=FAIL_SAFE, **0**=EXPLORE, **1**=EXPLOIT, **2**=TARGET_ACHIEVED |
| `epsilon` | Exploration rate (0.0=exploit only, 1.0=explore only). Decays by 0.95/cycle. |
| `q_value` | Q-value of selected action |
| `reward` | Observed reward = `|setpoint-obs_before| - |setpoint-obs_after|` |
| `depth` | Q-table search depth (0=exact, higher=interpolated) |
| `historic_rewards_matched` | Count of matching historical rewards |
| `freshness` | Recency score of matched rewards |
| `similarity` | State similarity score (threshold: 0.8) |
| `action` | The computed action delta (step_size_max, -step_size_max, or 0) |

### Step 6: RL Failures (InfluxDB — rl_failed)

```
bucket: cpa_logs_30_days
measurement: rl_failed
site_id: {site}
```

| error_code | Name | Meaning |
|------------|------|---------|
| `1` | `INSUFFICIENT_REWARDS` | No previous actions or gap > 24h |
| `2` | `OBSERVABLE_DATA_NOT_FOUND` | Sensor data missing from InfluxDB |
| `3` | `ACTION_DATA_NOT_FOUND` | Current action value not available |

### Step 7: Asset Selection (InfluxDB — asset_selection_config)

```
bucket: cpa_logs_30_days
measurement: asset_selection_config
site_id: {site}
```

Key fields: `observable_value`, `observable_min`, `observable_max`, `min_asset_required`, `asset_required`, `asset_running`, `selection_algorithm`, `asset_type`

Also check `ordering_config` for start/stop priority: `asset_id`, `ordering_param`, `score` (lower = start first)

### Step 8: TI Events (InfluxDB — ti_events)

Query when investigating Tonnage Injection issues:
```
bucket: cpa_logs_30_days
measurement: ti_events
site_id: {site}
```

Fields: `state` (0-5), `coolewt`, `chiller_off_trig`, `chiller_on_trig`, `chiller_boot_trig`

### Step 9: Edge Health & IoT Metrics (InfluxDB + Loki)

**Quick JouleBox Health Check (recommended first query):**
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -10m)
  |> filter(fn: (r) => r["_measurement"] == "jouleboxhealthandstate")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: ["_value"])
```

`jouleboxhealthandstate` — THE best single measurement for JouleBox health:
- `healthscore` (float, 0-100) — overall health percentage
- `networkhealth` (int, 0/1) — network connectivity
- `overallhealth` (int, 0/1) — overall health flag
- `postresqlhealth` (int, 0/1) — PostgreSQL database health (note: typo in field name is intentional — "postresql" not "postgresql")
- `ssdhealth` (int, 0/1) — SSD storage health
- `state` (int) — 1=master, 2=CPA/slave

Healthy: healthscore=100, all flags=1. Degraded: healthscore<100 or any field=0. Down: no records.

**Controller uptime (identifies offline controllers):**
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "controllerservicesuptime_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> aggregateWindow(every: 5m, fn: last, createEmpty: false)
```

Fields: `uptimestatus` (int, 1=UP, 0=DOWN). If `uptimestatus=0` persistently, that controller's devices won't have fresh data.

**Controller reboots:**
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "controllerrestart")
  |> filter(fn: (r) => r["siteid"] == "{site}")
```

Fields: `restarttime` (string, timestamp of last reboot)

**Container restarts:**
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "containersrestart")
  |> filter(fn: (r) => r["siteid"] == "{site}")
```

Fields: `status` (string, values: "success"). Tags: `container`, `controllerid`, `controllertype`, `siteid`

**NAS & Network connectivity:**
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "basicnetworkhealth")
  |> filter(fn: (r) => r["siteid"] == "{site}")
```

Fields: `nasconnectionstatus` (float, 1.0=connected, 0.0=disconnected)

**Component data quality:**
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -6h)
  |> filter(fn: (r) => r["_measurement"] == "componentdataqualityabsolute_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
```

Fields: `Expected`, `ActualNonNull`, `NullDeviceParams`, `DataExpressionEvalError`, `DataExpressionSyntaxError`, `DataExpressionBadOperandError`, `AbsentDeviceParams`, `ContextNotFound`, `OutOfBoundsError`, `MaintenanceMode`, `SiteIsDown`
Quality formula: `ActualNonNull / Expected * 100`. Tags: `componentid`, `siteid`

**Device-level data quality** (complementary to component-level):
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -6h)
  |> filter(fn: (r) => r["_measurement"] == "devicedataquality_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
```

---

### Step 9b: Edge Logs (Loki)

> **Loki URL**: Use `url: https://loki-2.smartjoules.org` for ALL Loki queries (both edge and CPA logs).
> Available labels: `iot_controllerid`, `iot_job`, `iot_service_name`, `iot_siteid`

Use `mcp__grafana__query_loki_logs`:

**CPA-specific logs**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="chillerplantautomation"} |~ "{keyword}"
```

**Edge health logs**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="firmware"} |~ "(?i)(NoResponseError|error|exception)"
```

All queries use `url: https://loki-2.smartjoules.org`:

**HIGH-VALUE Loki queries (check these FIRST for any modulation issue)**:

| Scenario | LogQL filter | What to look for |
|----------|-------------|-----------------|
| **Actual setpoint being used** | `\|~ "The setpoint for the observable"` | Shows `"The setpoint for the observable {name} is {value}"` — confirms WHICH target RL is using. Cross-check with profile. |
| **Fail-safe firing** | `\|~ "out of bounds"` | `"{observable} out of bounds, increasing/decreasing control command : {value}"` — RL NOT optimizing, just pushing in one direction |
| **Active profile** | `\|~ "Current Profile"` | `"Current Profile: Monday_08:00:00_18:00:00"` — confirms which time slot is active |
| **Observable fetch** | `\|~ "fetch_observable_data"` | Shows which chiller IDs are queried and actual sensor values |

**Standard Loki queries**:

| Scenario | LogQL filter | What to look for |
|----------|-------------|-----------------|
| Safety net status | `\|~ "Safety Net" \|~ "{asset_id}"` | `DISABLED` vs `state set to Emergency State` |
| Safety net modulate proof | `\|~ "{asset_id}.*Emergency State"` | Presence = modulate safety net IS firing |
| Command failures | `\|~ "Command.*failed" \|~ "{asset_id}"` | Event details |
| Mode mismatch | `\|~ "ASSET_NOT_IN_RECIPE_MODE"` | BMS not in auto mode |
| TI state changes | `\|~ "TonnageInjection\|TI_"` | State machine transitions |
| OAT failsafe | `\|~ "OAT_FAILSAFE\|HUMIDITY_FAILSAFE"` | Emergency triggers |
| Asset selection | `\|~ "asset_selection_manager"` | Selection decisions |
| Flow-based freq | `\|~ "set_flow_based_frequency"` | Pump frequency setting |
| CPA service health | `\|~ "(?i)(error\|exception\|restart)"` | CPA crashes |
| Config refresh | `\|~ "refresh_profile"` | Profile loading |
| Firmware errors | `iot_service_name="firmware"` | NoResponseError, Modbus failures |
| Firmware NoResponseErrors | `iot_service_name="firmware"` `\|~ "NoResponseError"` | Dead VFDs/sensors (all params = device unresponsive) |
| Container restarts | `iot_service_name="hostservice"` | Service restart events |
| Service start/stop/fail | `iot_service_name="(systemd)"` `\|~ "Started\|Stopped\|Failed"` | Service lifecycle events |
| Edge service health | `iot_service_name="systemd"` | aws-jobs, joule-recipe crashes |

**Available service names on Loki** (`loki-2.smartjoules.org`):
firmware, application, gateway, hostservice, joule-recipe, metrics-upload, edgebolt, edgeboltfrontend, nas-interface, telegraf, promtail, systemd, containerd, dockerd, aws-iot-device-client, ahu-auto-*

### Step 10: Code Analysis (Morpheus — if needed)

Key source files:

| File | What it does |
|------|-------------|
| `src/automation/optimization.py` | ALL optimization algorithms (3800+ lines) |
| `src/asset_selection/asset_selection_manager.py` | Selection orchestrator |
| `src/asset_selection/zone_division_on_param_value.py` | Zone division selection |
| `src/asset_selection/design_flow_pump_selector.py` | Flow-based pump selection |
| `src/asset_selection/asl_forecast_asset_selection.py` | DL forecast selection |
| `src/asset_selection/ordering_strategy.py` | Asset start/stop ordering |
| `src/assets/plant_orchestrator.py` | Safety net, plant management |
| `src/assets/command_feedback.py` | Command lifecycle, alerts |
| `src/helper_functions/event_csv_gen.py` | All InfluxDB logging |
| `src/automation/alert.py` | Alert types, MQTT publishing |
| `configuration/software-conf.yml` | event_type → event_id mapping |

---

## Optimization Algorithm Reference

All live in `src/automation/optimization.py`. Config key is set via `modulate_action.optimization.logic` in the profile.

### 1. `q_based_rl` — QBasedRL (Most Common)

**Controls**: Any modulate_action asset (CTs, pumps, chillers). Q-learning with epsilon-greedy.

**How it works:**
1. Checks if target achieved (observable within 0.5% of setpoint) → logs `TARGET_ACHIEVED`, no action
2. Computes action direction from error: `error = target - observable`. If error*direction > 0 → action = `[+step_size_max]`. If < 0 → `[-step_size_max]`. If within 0.5% → `[0]`
3. **Epsilon-greedy**: with probability `epsilon` picks random action, otherwise picks best via Q-values
4. Q-value computation: searches historical rewards where state matches (similarity >= 0.8). Reward = `|setpoint-obs_before| - |setpoint-obs_after|`. Weighted by freshness and popularity. Depth=1, gamma=0.85
5. Epsilon decays by 0.95 each cycle

**Logs**: `q_rl_actions_explained` (op_mode, q_value, reward, similarity, freshness), event_type=`rl_optimize`

**Diagnose**: Check `q_rl_actions_explained.op_mode`. If `-1` (fail_safe) → observable outside bounds. If `0` (explore) with high epsilon → still learning. If `historic_rewards_matched=0` → no Q-table coverage.

### 2. `q_based_rl_expected_sarsa` — QBasedRL_ExpectedSarsa

**Same as `q_based_rl` except**: Instead of `max(Q)` for next state, uses `mean(Q)` across all possible next actions. Less optimistic — accounts for average policy. Better when exploration is high.

### 3. `q_based_rl_sarsa` — QBasedRL_Sarsa

**Same as `q_based_rl` except**: For next state, actually samples the next action using the SAME epsilon-greedy policy. On-policy learning — Q-values reflect actual behavior including exploration mistakes. More conservative than Q-learning.

### 4. `single_objective_rl` — SingleObjectiveRL

**Controls**: Same asset types. Weighted reward accumulation.

**How it works:**
1. Iterates through last 7 days of rewards from `kakashi` table
2. For each reward: `alpha = 1/(index+1)`, `weight = (1-alpha)^(count-index)`
3. `delta = |setpoint-obs_before| - |setpoint-obs_after|` (positive = improvement)
4. Accumulates: `weight * delta + STEP_SIZE * direction`
5. If no rewards: falls back to `initial_bias` point (~60% of range)
6. Scales by energy_ratio, caps to bounds

**Logs**: event_type=`rl_optimize`. No `q_rl_actions_explained`.

### 5. `multi_objective_rl` — MultiObjectiveRL

**Controls**: CTs or any asset where both observable AND energy matter.

**How it works**: Same as SingleObjectiveRL but with TWO reward terms:
- **Primary** (weight 0.51): improvement in observable (condewt getting closer to target)
- **Secondary** (weight 0.49): reduction in energy (chiller kW + own kW)
- If energy saved: both terms contribute positively
- If energy increased: secondary term penalizes

**Logs**: Rewards stored in `zetsu` table (multi_objective_rewards). Queries chiller kW via `observable_chillers`.

### 6. `tonnage_injection` — TonnageInjection

**Controls**: Chillers + condenser circuit (pumps, CTs). State machine for chiller staging.

**How it works** (state machine based on `coolewt` — chilled water return temperature):

| State | ID | Condition | Action |
|-------|-----|-----------|--------|
| `TI_INIT` | 0 | `off_trig < coolewt < on_trig` AND chiller ON | Set chiller to min_sp, keep condenser ON |
| `CHILLER_BOOTING` | 1 | `coolewt > chw_in_trig` | Start condenser, ramp chiller SP from `coolewt - delta` down to `min_sp`. 60min timeout. |
| `CHL_OFF_CONDWP_OFF` | 2 | `coolewt <= off_trig + offset` AND chiller confirmed OFF | Stop chiller AND condenser circuit |
| `CHL_OFF_CONDWP_ON` | 3 | `coolewt <= off_trig` | Stop chiller, keep condenser ON |
| `CHL_ON_CONDWP_ON` | 4 | `coolewt > on_trig` AND no boot needed | Start chiller AND condenser circuit |
| `TI_UNKNOWN` | 5 | Gray zone | Preserves previous state (hysteresis) |

**Key profile params**: `off_trig_sp`, `on_trig_sp`, `chw_in_trig` (boot trigger), `chiller_delta`, `min_sp`, `off_trig_sp_offset`

**Logs**: `ti_events` measurement with state/coolewt/triggers. event_type=`ti_optimize`.

**Diagnose**: Check `ti_events` for state oscillation (rapid 3↔4 transitions). Check if `off_trig_sp` and `on_trig_sp` are too close. Check boot timeout (state stuck at 1 for 60+ min).

### 7. `oat` — OatBased

**Controls**: Chiller setpoint based on Outside Air Temperature.

**How it works:**
1. Reads OAT sensor value
2. If `OAT > tmp_max` → **OAT_FAILSAFE**: set chiller to `emergency_value`
3. If `OAT < tmp_min AND humidity > hum_max` → **HUMIDITY_FAILSAFE**: set to `emergency_value`
4. If `OAT >= threshold` → set to `min_sp` (maximum cooling)
5. Otherwise: `SP = min_action + (threshold - OAT) / param_step_size * step_size` (as OAT drops, SP increases — less cooling needed)

**Cycle**: Every 30 minutes.

**Key profile params**: `mode` (sensor), `threshold`, `tmp_max`, `tmp_min`, `hum_max`, `param_step_size`, `step_size`, `min_sp`

**Logs**: event_type=`oa_optimize`. Check Loki for `OAT_FAILSAFE` / `HUMIDITY_FAILSAFE`.

### 8. `asl_forecast_dl_control` — AslForecastDlControl

**Controls**: Any modulate_action asset. Pure lookup — gets target from PlantSolutionManager (pre-computed DL solutions indexed by wetbulb + tonnage).

**How it works**: Every 30 seconds, queries `plant_solution_manager.get_modulate_action(asset_id, device_type)` and applies the returned value directly. No learning.

**Logs**: event_type=`asl_forecast_dl`

**Diagnose**: If PlantSolutionManager returns None → no action. Check if solution DB is populated for current wetbulb/tonnage conditions.

### 9. `q_rl_lookUP` — QRlLookup

**Controls**: Same as QBasedRL but gets setpoint from PlantSolutionManager instead of profile config.

**How it works**: Same Q-learning as `q_based_rl`, but the `setpoint` comes from the DL solution DB rather than a fixed profile `target`. Combines learned execution (Q-learning) with DL-predicted targets. No energy_ratio scaling — each asset gets independent commands.

**Logs**: event_type=`q_rl_lookup_optimize`, plus `q_rl_actions_explained`.

---

## Asset Selection Algorithm Reference

All live in `src/asset_selection/`. Config key is set via `start_action.optimization.logic` in the profile. Managed by `AssetSelectionManager` which caches results for 300s.

### 1. `asl_zone_division_on_parameter_value` — Zone Division

**Controls**: CTs, condenser pumps — any asset where count should vary with load.

**How it works:**
1. Reads configured parameter (e.g., `condewt`) averaged over `sample_time` minutes
2. `assets_on = round((param_value - range_min) / (range_max - range_min) * total_assets)`
3. Clamped to `[min_asset, total_assets]`. Below range_min → 0. Above range_max → all.
4. If sensor returns None → falls back to `min_asset`

**Key profile params**: `start_action.optimization.info.param`, `ranges[param].min/max`, `min_asset`, `sample_time`

**Logs**: `asset_selection_config` with `observable_value`, `observable_min/max`, `asset_required`, `selection_algorithm = "asl_zone_division_on_parameter_value"`

**Diagnose**: Check if `observable_value` is within expected range. If always returning `min_asset` → sensor may be offline.

### 2. `asl_design_flow_pump_selector` — Design Flow Pump Selector

**Controls**: Pumps (condenser water, primary chilled water). Determines count AND frequency.

**How it works:**
1. Calculates required flow from operational chillers (`sum(rated_flow)`)
2. Loads pre-computed flow dictionary (maps flow → pump combinations with frequencies and power)
3. Solves LP (PuLP/CBC): minimize power, constraints = pump count bounds, frequency bounds, flow within ±15 of required
4. If infeasible: searches by incrementing/decrementing flow by 30 until solution found
5. Publishes frequency via `set_flow_based_frequency` event: sets `min_frequency`, `recommended_modulate_action`, `max_frequency` for RL to use

**Key profile params**: `min_pumps`, `max_pumps`, `modulate_action.info.min/max` (frequency bounds)

**Logs**: `asset_selection_config` with `required_flow`, `pumps_required`, `expected_power_consumption`, `calculated_flow`, `selection_algorithm = "asl_design_flow_pump_selector"`

**Diagnose**: Check if `InfeasibleSolution` in Loki. Check if `observable_chillers` is populated. Check flow dict file exists.

### 3. `asl_fixed_number_of_assets_running` — Fixed Count

**Controls**: Any asset type. Always runs exactly N assets.

**How it works**: Returns `num_of_assets` from profile config. No computation.

**Key profile params**: `start_action.optimization.info.num_of_assets`

### 4. `asl_forecast_dl_control` — DL Forecast Selection

**Controls**: Any asset type. Uses PlantSolutionManager to predict how many assets are needed.

**How it works:**
1. Gets current `wetbulb` and `tonnage` from PlantSolutionManager
2. Queries solution for optimal plant configuration at those conditions
3. Counts assets of requested type with `start_action=True` in solution
4. For chillers: orders by solution preference. For others: uses ranking file keyed by wetbulb
5. Clamped to `[min_assets, max_assets]`

**Diagnose**: If wetbulb/tonnage is None → returns `min_assets`. Check solution DB coverage.

### Ordering Strategy

When selection algorithm returns a count but no sorted list, `OrderingStrategy` decides which assets start first:

1. For each asset, reads configured parameters (e.g., `runminutes`)
2. Normalizes values to [0,1] across all assets
3. Multiplies by weight, adjusts for direction
4. **Lowest total score = started first**

Common config: `runminutes` with `direction=1` → asset with LEAST run hours starts first (load balancing).

Logged to `ordering_config` measurement.

---

## Alerts Reference

Published via MQTT (`smart/alert`), visible in Loki. NOT in InfluxDB.

| Alert ID | Trigger | Meaning |
|----------|---------|---------|
| `UNABLE_TO_TURN_ON_ASSET` | feedback failure `[0,3,6]` for start | Start command failed |
| `UNABLE_TO_TURN_OFF_ASSET` | feedback failure `[0,3,6]` for stop | Stop command failed |
| `UNABLE_TO_MODULATE_ASSET` | feedback failure `[0,3,6]` for modulate | Modulation failed |
| `ASSET_NOT_IN_RECIPE_MODE` | feedback status `8` | BMS not in auto mode |
| `SUPERSEDE_CONDITION_MET_OFF` | Safety net forces OFF | Safety net stop override |
| `SUPERSEDE_CONDITION_MET_ON` | Safety net forces ON | Safety net start override |
| `SUPERSEDE_CONDITION_MET_MODULATE` | Safety net forces modulation | Safety net modulate override |

Events: `OCCURRED` (problem) or `RESOLVED` (cleared). Recurring `RESOLVED` every minute is normal.

---

## Output Format

```
## RCA: {Site Name} ({site_id}) — {Issue Title}

**Reported Issue**: {original complaint}
**Time Window**: {time range investigated}
**Algorithm**: {optimization_logic from profile} — {algorithm name}

### What SHOULD be happening
{From Neo4j — assets, algorithm, parameters, safety nets}

### What IS happening
{From InfluxDB — actual decisions, events, command results}

### Root Cause
{Config issue / Operational issue / Code bug / Normal behavior misidentified}

### Evidence
{Specific timestamps, values, event types}

### Recommendation
{Config change / Hardware check / Code fix / No action needed}
```

---

## Common Patterns

### "CT frequency stuck high"
1. **FIRST check Loki** for the actual setpoint and fail_safe status:
   - `|~ "condmhrtemp"` → look for `"The setpoint for the observable condmhrtemp is X.0"` (confirms which target RL is using)
   - `|~ "fail_safe"` → look for `"condmhrtemp out of bounds, increasing control command"` (THIS IS THE #1 CAUSE)
2. If `fail_safe` is firing → the observable is **outside the configured `rangeMin`-`rangeMax` bounds**. At night, condenser approach drops naturally. If range is set for daytime (e.g., 23-25.5°C) but actual value is 20°C → fail_safe keeps pushing frequency UP every cycle. **Fix: widen the range bounds for night profiles.**
3. Check `asset_optimize` → is `obs_before_state` near/above `setpoint`?
4. If YES → correct. Ambient conditions require it.
5. If NO → check `command_feedback` for status `8`/`-1`/`7`
6. Check `q_rl_actions_explained.op_mode`: `-1` = fail_safe (obs outside bounds), `0` = exploring
7. Check if `multi_objective_rl` is configured → secondary energy term may be penalizing frequency reduction
8. **Check profile architecture**: Is the `@all` profile target different from individual profile target? (see Step 1 notes on `@all` vs individual profiles). Config sheet may show target=4 (`@all`) but individual profiles have target=2.
9. **Check asset selection**: Is `min_asset` set equal to total CT count? If so, ALL CTs are forced on regardless of load. At night with low load, this wastes energy and prevents CT count reduction.

### "Observable out of bounds / fail_safe firing constantly"
1. Check Loki: `|~ "out of bounds"` → confirms fail_safe is active
2. The log format is: `"{observable} out of bounds, increasing/decreasing control command : {value}"`
3. This means the observable's current value is **outside `rangeMin`-`rangeMax`** configured in the profile
4. Common at night: daytime range bounds (e.g., condmhrtemp 23-25.5°C) don't account for nighttime drop (actual 19-21°C)
5. Check which profile slot is active: Loki `|~ "Current Profile"` → shows `Monday_08:00:00_18:00:00` etc.
6. **Fix**: Widen `ranges.{observable}.min/max` in the `@all` profile for the night slot to cover actual nighttime values
7. The fail_safe pushes frequency in the direction that would bring the observable INTO range — if obs < rangeMin, it INCREASES frequency (more cooling), which is the opposite of what you want at night

### "Safety net not working"
1. Check Neo4j → `safetyNetEnabled=true` AND `safetyExpression` populated?
2. Check Loki for `"{asset_id}.*Emergency State"` — presence = modulate safety net IS firing
3. Check Loki for `"Safety Net [{asset_id}@stop_action]"` — enabled/disabled per action
4. **Modulate evaluation logs are DEBUG level.** Only INFO proof is `"Emergency State"`
5. Check `asset_event` for event_type=`safety_net` (id=10)
6. If safety net fires but no visible effect → check if `operatingMin == operatingMax` (RL already locked)
7. `UNABLE_TO_MODULATE_ASSET (RESOLVED)` every minute is NORMAL when condition not met

### "Chiller not starting/stopping"
1. Check Profile → `intendedState`
2. Check `command_feedback` → `action_status`? Status `8` = BMS not in recipe mode. `-1`/`7` = timeout.
3. Check `asset_selection_config` → is selection algorithm requesting right count?
4. If TI configured → check `ti_events` for state. Is TI keeping chiller OFF (state 2/3)?
5. Check topology → pump must start before chiller

### "TI oscillating / chiller boot stuck"
1. Check `ti_events` → rapid state changes between 3↔4 (CHL_OFF_CONDWP_ON ↔ CHL_ON_CONDWP_ON)
2. If oscillating → `off_trig_sp` and `on_trig_sp` are too close. Need wider deadband.
3. If boot stuck (state=1 for 60+ min) → chiller can't reach `min_sp`. Check if `chiller_delta` is too large or chiller has mechanical issue.
4. If state=5 (TI_UNKNOWN) persisting → coolewt is in gray zone between triggers

### "High kW / inefficient"
1. Check `asset_selection_config` → `asset_required` vs `asset_running` (too many running?)
2. Check `asset_optimize` for chillers → is `action_after_state` (setpoint) too low?
3. Check `q_rl_actions_explained.op_mode` → `-1` (fail_safe) uses emergency values which may be aggressive
4. If `multi_objective_rl` → check if secondary energy term weight is working (0.49)
5. Check CT/pump frequencies → all at max = condenser side saturated

### "Optimization not running"
1. Check Profile → `optimizationEnabled` for current slot
2. Check `asset_optimize` → any records?
3. If none → check `rl_failed`: code 1 (no rewards/24h gap), code 2 (sensor offline), code 3 (action value missing)
4. Check `asset_event` for `data_not_available` (id=2)
5. Check if `alternate_cycle` applies — multi-asset-type groups take turns. May appear idle on off-cycles.

### "Wrong number of assets running"
1. Check `asset_selection_config` → `selection_algorithm`, `asset_required` vs `asset_running`
2. If `zone_division` → is `observable_value` within the configured `min/max` range? Sensor offline → falls back to `min_asset`
3. If `design_flow_pump_selector` → check for `InfeasibleSolution` in Loki. Check `required_flow` vs pump capacity.
4. If `forecast_dl` → check if PlantSolutionManager has solutions for current wetbulb/tonnage
5. Check `ordering_config` → asset scores determine which ones start/stop
6. Check safety net → may be overriding selection (forcing ON/OFF)
7. Selection is cached 300s — changes may be delayed

### "Pump frequency wrong"
1. Identify selection algorithm: if `design_flow_pump_selector` → frequency comes from LP optimization, NOT from RL
2. Check `asset_selection_config` → `required_flow`, `calculated_flow`, `required_frequency`
3. The pump selector publishes `min_frequency`, `recommended_modulate_action`, `max_frequency` which OVERRIDE the RL's operating range
4. If frequency seems wrong → check if flow dict file is correct, check if `observable_chillers` count matches actual running chillers

### "Commands failing"
1. Check `command_feedback` → group by `action_status`
2. Status `8` dominant → BMS mode issue (not CPA)
3. Status `-1`/`7` dominant → JouleBox communication
4. Status `0`/`3`/`6` dominant → equipment-level failure
5. Trace: `asset_event.UUID` → `command_feedback.UUID`

### "Whole plant stopped unexpectedly"
1. Check Loki for `"Plant {plant_id}: current=OFF"` or `"circuits_healthy=False"`
2. **Circuit health**: Plant orchestrator checks circuits BEFORE starting chillers. If ANY required circuit (CHW pumps, CW pumps, CTs) is UNHEALTHY, the plant stays OFF
3. Circuit states: `HEALTHY=1`, `UNHEALTHY=2`, `OPTIMIZE=3`. A transition failure → UNHEALTHY → plant stops
4. Check `"set_circuit_unhealthy"` in Loki — this is called when hardware state updates detect issues
5. Check if pump/CT selection returned 0 assets → circuit has no operational assets → UNHEALTHY
6. For multi-plant sites: each `plant_id` is independent. Plant A can be ON while Plant B is OFF

### "Valve not opening / chiller can't start after selection"
1. Plant orchestrator manages valves via `_manage_chiller_valves` in Step 7
2. Chiller `ready_to_start` requires: `condenser=True` AND `chwp=True` (condenser circuit + CHW pump must be operational BEFORE chiller starts)
3. Check Loki for `"ready_to_start=False"` — tells which prerequisite failed
4. Check if valve commands are being sent: `command_feedback` with `param_name` containing `valve`
5. Dual valve chillers have separate open/close valve control — check `DualValve` command config in `cpa-conf-csv-gen`

### "CPA using emergency values / emergency mode"
1. Check `asset_event` for `emergency_mode_edge` (id=4) or `emergency_mode_central` (id=3)
2. **Edge emergency mode**: Edge controller (`src/automation/edge.py`) monitors `central_health_topic`. If no "pong" from central within `EMERGENCY_MODE_TIMER`, CPA switches to emergency values
3. Check Loki for `"Start Edge_workflow"` or `"Emergency Mode"` — confirms edge lost contact with central
4. Emergency values come from profile's `emergencyValue` field — check if they're appropriate
5. This is DIFFERENT from `rl_fail_safe` (which is RL-internal). Emergency mode bypasses RL entirely.

### "RL converging to wrong setpoint"
1. Check if `recommendations_enabled=true` in profile — means RL gets setpoint from `DLSetPointCalculator` (CPC models), NOT from profile `target`
2. If DL recommendation is wrong: check `recommended_value` in `asset_event` — does it match expected range?
3. `DLSetPointCalculator` has `PREDICTED_EXPIRY_PERIOD = 1 min` — predictions expire quickly. If model inference is slow/stale, RL falls back to profile target.
4. For `q_rl_lookUP`: setpoint comes from `PlantSolutionManager` (pre-computed solutions indexed by wetbulb + tonnage). Check if solution DB has entries for current conditions.

### "Mode mismatch — thermostat/recipe commands rejected"
1. This is NOT a CPA issue — it's `iot-application` level command validation
2. Check Loki: `"Command source {X} does not match mode {Y}"` with `status_code=8`
3. Common patterns:
   - `source=joulerecipe, mode=jouletrack` → controller is in JouleTrack mode, recipe commands rejected
   - `source=thermostat, mode=jouletrack` → thermostat commands rejected because controller is in JouleTrack mode
   - `source=thermostat, mode=joulerecipe` → thermostat commands rejected because controller is in recipe mode
4. Fix: change controller mode in JouleTrack UI to match the command source
5. This affects LOW-SIDE equipment (AHUs, FCUs, thermostats) — CPA high-side assets have separate mode handling

### "Safety net expression has a typo / malformed number"
1. Observed pattern: `29.7.0` (double decimal) in safety expression → condition NEVER evaluates to True
2. Check Neo4j `safetyExpression` for malformed numbers — search for patterns like `\d+\.\d+\.\d+`
3. Check `command_feedback` for status `14` (wrong syntax in feedback expression) — high count of status 14 = expression parsing failure
4. ALL CTs at a site often share the SAME safety expression — one typo breaks all of them
5. Fix in Google Sheet → regenerate config → verify in Loki for `"Emergency State"` after fix

---

## Plant Orchestrator Flow (8 Steps)

CPA runs this cycle every ~30 seconds via `manage_all_plants()`:

```
Step 0: Safety net evaluation (HIGHEST PRIORITY)
   ↓
Step 1: Global chiller selection (if global_chiller_circuit configured)
   ↓
Step 2-3: Per-plant chiller circuit selection
   ↓
Step 4: Supporting asset selection per plant (pumps, CTs)
   ↓
Step 5: Shared resource selection (assets with plant_id="all")
   ↓
Step 6: Plant state determination (ON/OFF based on chillers + circuit health)
   ↓
Step 7: Plant circuit transitions (valve management, chiller ready_to_start checks)
   ↓
Step 8: Shared resource transitions
```

**Key**: Steps 6-7 check `circuits_healthy`. If any circuit is UNHEALTHY, the plant intended_state = OFF even if chillers are selected.

**Multi-plant sites**: Each `plant_id` runs independently through Steps 2-7. Shared resources (Step 5, 8) are common across all plants.

---

## InfluxDB Tag Names & Morpheus Tool

> **MORPHEUS TOOL LIMITATIONS:**
> - `mcp__morpheus__influx_schema` only knows about `cpa_logs_30_days` and `device_component/autogen`. It does NOT know about `iot-cloud-metrics` or `iot-metrics` measurements.
> - `mcp__morpheus__query_metrics` `site_id` parameter only maps to `site_id` tag (`cpa_logs_30_days`). For `iot-cloud-metrics` and `iot-metrics`, MUST use `raw_flux` with `r["siteid"]` filter.
> - Always use `raw_flux` for `iot-cloud-metrics` and `iot-metrics` queries.

> **CRITICAL: Site tag names differ per bucket:**
> - `cpa_logs_30_days` bucket → `site_id` tag (underscore). The `mcp__morpheus__query_metrics` tool's `site_id` parameter works for this bucket.
> - `iot-cloud-metrics` bucket → `siteid` tag (all lowercase, no separator). Must use `raw_flux` with `r["siteid"] == "{site}"`.
> - `iot-metrics` bucket → `siteid` tag (all lowercase). Must use `raw_flux`.
> - `data-errors-context` bucket → tag name unknown, check schema.
>
> Example `raw_flux` for non-CPA buckets:
> ```
> raw_flux: from(bucket: "iot-cloud-metrics")
>   |> range(start: -1h)
>   |> filter(fn: (r) => r["_measurement"] == "controllerconnectivity_1")
>   |> filter(fn: (r) => r["siteid"] == "{site}")
>   |> aggregateWindow(every: 5m, fn: last, createEmpty: false)
> ```

### Measurement Lists

**iot-cloud-metrics** (19 measurements):
```
controllerconnectivity_1, controllerconnectivity
gatewayconnectivity_1, gatewayconnectivity
componentdataqualityabsolute_1, componentdataqualityabsolute
devicedataquality_1, devicedataquality
controllerservicesuptime_1, controllerservicesuptime
controllerpackagesversions_1, controllerpackagesversions
absentdevicecontribution_1, absentdevicecontribution
nulldevicecontribution_1, nulldevicecontribution
lokicpu, lokidisk, lokimem
```

**iot-metrics** (28 measurements):
```
awsbroker, basicnetworkhealth, bmsxdevicemetricsv2, bmsxobjectmetricsv2,
commandstatus, containersping, containersrestart, controllerrestart,
cpuhealth, devconfigupdate, diskio, diskusage, gatewaybroker,
joulebox_services_status, jouleboxhealthandstate, networkinfo,
networkusage, pingstats, processesresourceusage, recipeeval,
recipeupdate, resourceusage, retentionrecipeassetstate,
retentionrecipecommandslog, service_detail, ssdstatus,
systemd_service_health, thermostat
```

**cpa_logs_30_days** (known measurements):
```
asset_state, asset_event, asset_optimize, command_feedback,
rl_failed, q_rl_actions_explained, asset_selection_config,
ordering_config, ti_events
```

## Important Notes

- **`condition_not_met` (id=1) is the DEFAULT event.** Fires every cycle. NOT a failure.
- **`setpoint` in asset_optimize = RL target for the observable**, not the equipment setpoint.
- **Safety net modulate logs are DEBUG level.** Proof = `"Emergency State"` at INFO.
- **`UNABLE_TO_MODULATE_ASSET (RESOLVED)` is not a failure.**
- **`ASSET_NOT_IN_RECIPE_MODE`** = BMS operational issue, not CPA bug.
- **Summer**: Higher ambient = CTs faster, chillers harder. Normal.
- **Safety net has 3 separate enables**: start_action, stop_action, modulate_action per time slot.
- **Asset selection is cached 300s.** Changes may not reflect immediately.
- **Alternate cycle**: When multiple asset types share an observable, they take turns. Cycle = `sample_time * num_asset_types`.
- **Energy ratio**: In RL, each asset's delta is scaled by its share of total rated kW among operational assets.
- **Design flow pump selector overrides RL frequency range** via `set_flow_based_frequency` event.
- **TI resets selection cache** on every state transition — forces re-selection of pumps/CTs.
- **Trace end-to-end**: `asset_event` (UUID) → `command_feedback` (UUID) → Loki (detailed logs)
- **Config key locations**: Modulation algorithm = `modulate_action.optimization.logic`. Selection algorithm = `start_action.optimization.logic`.
- **Multi-plant sites**: Each `plant_id` is independently managed. One plant can be ON while another is OFF. Always check per-plant, not just per-site.
- **Circuit health gates plant start**: If ANY required circuit (CHW pumps, CW pumps, CTs) is UNHEALTHY, the plant stays OFF. Check `circuits_healthy` in Loki.
- **Valve prerequisite**: Chiller `ready_to_start` requires `condenser=True AND chwp=True`. Valve open must complete before chiller can start.
- **Central/Edge emergency**: Edge controller pings central on `central_health_topic`. No pong within `EMERGENCY_MODE_TIMER` → emergency mode with emergency values. Different from `rl_fail_safe`.
- **DL recommendations**: When `recommendations_enabled=true`, RL setpoint comes from `DLSetPointCalculator` (CPC models). Stale model = RL chasing wrong target.
- **Mode mismatch is NOT CPA**: `Command source X does not match mode Y` is `iot-application` level. Affects thermostats/recipes/low-side. Fix in JouleTrack controller settings.
- **Safety expression typo pattern**: Double decimals like `29.7.0` silently break conditions. Check `command_feedback` status `14` (syntax error) as a signal. All CTs at a site often share the SAME expression.
