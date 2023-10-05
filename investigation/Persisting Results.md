# Persisting Results

Persisting the results of monitoring a test can be done different ways, which
all have their up- and downsides.

- Grafana Screenshots

  Can also be created "full-page", not only the viewport.

  - Easily shareable
  - Unmodifiable

- Grafana Snapshots

  Ought to be mostly self-contained. Does not require a data source, but does
  require the data stored in the SQLite database of Grafana to be visible.

  - PromSQL queries for comparable data.

  - Filtering data is limited in snapshots.

  - Public

    Publicly reachable URL.

  - Local

    - Stored in a SQLite database table of Grafana.

    - Issue with saving the complete data of a Dashboard. Apparently only the
      current viewport is being saved when a snapshot is created.

      Perhaps related to
      https://community.grafana.com/t/snapshot-shows-not-all-data-datasource-ms-sql-server/62486/2

      - [x] Verify
      - [x] Needs an increase of a timeout.

    - Requires locally running Grafana instance but not an appropriate data
      source (TODO: verify).

- Prometheus Snapshots

  - Basically Prometheus' way of creating backups.
  - Snapshots can be restored by replacing existing data store of a Prometheus
    instance (apparently not incrementally).
  - API exists to trigger snapshots.
  - Most complete data, but viewing the data requires a Prometheus instance and
    a Grafana instance, so setup is a bit more complicated for "replay".
  - Not a good way to share it on a public URL.

- Other options exist but have been less extensive be evaluated

  - [Grafana Image
    Renderer](https://grafana.com/grafana/plugins/grafana-image-renderer)
