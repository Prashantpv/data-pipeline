# Minimal Observability Setup (EKS)

This directory provides a lightweight Prometheus-based setup for the data pipeline service.

## Included artifacts

- `prometheus-values.yaml`: values for `prometheus-community/prometheus` (lightweight profile).
- `sli-alert-rules-configmap.yaml`: native Prometheus alert rules with SLI thresholds.
- `prometheusrule-data-pipeline.yaml`: `PrometheusRule` equivalent for operator-based stacks.

## Why lightweight Prometheus

To keep resource usage and operational overhead low, this setup avoids the full
`kube-prometheus-stack` by default and focuses only on scraping annotated application pods.

## Metrics assumption

Rules assume application exposes:

- `http_requests_total` (with labels including `path`, `status`)
- `http_request_duration_seconds_bucket` (histogram buckets for latency)

If metric names differ, adjust the rule expressions accordingly.

## Logging note

Application logs are already structured JSON with `timestamp` and `request_id`.
For shipping logs from EKS to CloudWatch/OpenSearch, run Fluent Bit as a DaemonSet
and parse/pass through JSON fields.
