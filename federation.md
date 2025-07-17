# Federation Architecture

I want:

- Federated system with hierarchical nodes
- Federated prometheus
- Grafana alerting for text and metrics alerting. Alertmanager not used
- Ingesting alerts from a node into local prometheus and into loki

**Question:** Is it better to use a loki instance per node or one global loki instance?

## 1. IAM for Centralized Loki

To allow node-level log access with children included, do the following:

- Tag all logs with hierarchical label(s) like `node_path`
- Use Grafana datasources or query filters to restrict based on `node_path`
- Enforce access per folder/user/team in Grafana
- (Optional) Enforce query constraints using proxy or middleware

This is the standard approach used by companies deploying centralized Loki with per-tenant or hierarchical visibility, such as Grafana Labs and GitLab.

## 2. 🔧 Step-by-Step Implementation

### 2.1. Enforce strict label schema at ingestion

When logs are shipped (via promtail, vector, etc.), add structured labels to encode hierarchy:

```yaml
labels:
  org:      "corp-a"
  cluster:  "eu-central"
  node:     "node-12"
  parent:   "node-7"
```

Or encode parent as prefix:

```yaml
labels:
  node_path: "corp-a/region-x/node-12"
```

All logs must be tagged like this at ingest time. Do not allow unlabelled log streams.

### 2.2. Reflect hierarchy in label structure

Build hierarchy into the labels. Example:

| Node     | node label | node_path label              |
| -------- | ---------- | ---------------------------- |
| node-1   | node-1     | root/node-1                  |
| node-1a  | node-1a    | root/node-1/node-1a          |
| node-1a1 | node-1a1   | root/node-1/node-1a/node-1a1 |

Use this to restrict by path prefix.

### 2.3. Create one Loki data source per tenant (or use variable restriction)

#### 2.3.1. Option A: Per-tenant data source (recommended for strict isolation)

Define one Grafana data source per tenant (e.g. `loki_node-1`)

Set a label filter using `customQueryParameters` (Grafana >= 9.0):

```yaml
url: http://loki:3100
jsonData:
  derivedFields:
    - matcherRegex: ".*"
      url: ""
  maxLines: 1000
  queryParams:
    query: '{node_path=~"root/node-1(/.*)?"}'
```

→ Users of node-1 will see logs for node-1 and all its children.

#### 2.3.2. Option B: Use variables and regex restriction

Create a variable: `tenantNode = node-1`

Force all panels/queries to prefix with:

```logql
{node_path=~"root/${tenantNode}(/.*)?"}
```

⚠️ **Not secure by itself** — only works for honest users.

### 2.4. Restrict access via Grafana folders/teams

Create one Grafana folder per node

Grant access only to the corresponding users/team

Inside that folder:

- Use the scoped datasource
- Create dashboards that enforce label filtering

## 3. 🧪 Optional: Enforce label restriction with a reverse proxy (hard enforcement)

Grafana does not prevent users from editing queries by default.

If you require hard enforcement:
- Use a reverse proxy in front of Loki
- Inspect queries for `node_path` label
- Reject queries that violate tenant scope
- Or use Loki's multi-tenant mode with `X-Scope-OrgID` and custom tenant mapping

## 4. 🟡 Limitations

| Limitation                             | Impact                                   |
| -------------------------------------- | ---------------------------------------- |
| No native RBAC in Loki                 | Must enforce label-based access manually |
| No tree-awareness in Grafana UI        | Folder structure must mimic hierarchy    |
| Cannot hide logs without label filters | Relies on strict log labelling           |

## 5. Make the Alerts of a Node Accessible to Parents

To make the alerts of a node accessible to its parent nodes in a federated Prometheus + Grafana Alerting system, follow this pattern:

### 5.1. ✅ Problem

You use:
- Federated Prometheus hierarchy (e.g., node → region → global)
- Grafana Alerting only (no Alertmanager)
- Log and metric alerts
- Hierarchical access: parents must see alert state of child nodes

### 5.2. ✅ Solution: Export alert state as metrics in the node's Prometheus, and federate upward

### 5.3. 🔧 Step 1: Represent alerts as custom Prometheus metrics

Since Grafana Alerting doesn't expose alert state as time series, you must manually emit alert status into Prometheus:

#### 5.3.1. Option A: via Webhook → Sidecar → Prometheus

1. In each Grafana Alert, configure a webhook notification channel.
2. The webhook calls a local receiver script that writes to a Pushgateway or exporter.
3. The script maps alert payloads to custom metrics:

```prometheus
alert_state{alertname="DiskFull", severity="critical", cluster="node-7"} 1
```

4. The node's Prometheus scrapes this metric from Pushgateway or the exporter.

#### 5.3.2. Option B: Direct sidecar exporter

Implement a small exporter that:
- Receives alerts from Grafana (e.g. via REST or webhook)
- Exposes the current alert states at `/metrics` as Prometheus series

### 5.4. 🔧 Step 2: Federate alert metrics to parent Prometheus

In the parent Prometheus (region, global, etc.), configure:

```yaml
- job_name: 'federate-alerts'
  metrics_path: '/federate'
  params:
    'match[]':
      - '{__name__=~"alert_state"}'
  static_configs:
    - targets:
        - node7-prometheus:9090
```

Now the parent receives alert state from its children.

### 5.5. 📊 Step 3: Use alert metrics in dashboards and meta-alerts

In the parent Prometheus or Grafana:

**Show current alert states:**
```promql
alert_state{cluster="node-7"}
```

**Create meta-alerts:**
```yaml
- alert: RegionHasCriticalAlert
  expr: sum by(cluster) (alert_state{severity="critical"}) > 0
```

### 5.6. 📝 Optional: Write alert state to Loki for auditing

In the child node:

1. Send Grafana alert notifications (webhook or logs) into Loki
2. Include metadata:

```json
{
  "alert": "DiskFull",
  "status": "firing",
  "severity": "critical",
  "cluster": "node-7"
}
```

→ Grafana at parent level can show alert history via Loki

### 5.7. ✅ Final Architecture

| Layer | Responsibilities |
|-------|------------------|
| Node | Runs Grafana Alerting, emits alert state as metric, optionally logs it |
| Node Prometheus | Scrapes custom alert metrics (`alert_state{...}`) |
| Parent Prometheus | Federates child alert metrics |
| Parent Grafana | Dashboards + alerting based on aggregated alert metrics/logs |

### 5.8. ⚠️ Notes

- Alert state as metric is required because Grafana Alerting has no federated alert API
- Prometheus's `ALERTS` series is local only — not federated
- This pattern is used in real-world production to achieve alert visibility across Prometheus layers without Alertmanager