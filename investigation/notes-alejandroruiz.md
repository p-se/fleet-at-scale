### Outcome

#### New docs / guides

- How to setup Colima + Minikube (containerd & etcd-based k8s)
  - Install fleet and replace image with local version
- How to install Prometheus & Grafana for Kubernetes monitoring
  - Pre-defined Grafana dashboards
  - Adjust scrape configs to match expectations from Grafana boards
  - How to programmatically adding annotations to dashboards
- Samples of Cluster/Bundle/GitRepo objects?

#### Notes / ideas / caveats

- k3d vs. real downstream clusters 
  - Limit in number of local downstream clusters that can be created
  - Real clusters could be expensive
  - Running k3d clusters share CPU and networking, which does not match reality
- fake vs. full downstream clusters
  - Creating `Cluster` objects without a kubeconfig is effective to exercise the creation of RBAC resources, namespaces and even Bundle deployments.
  - Useful for measuring how CPU/memory behaves both at creation and in "standby" mode
  - However, `fleet-agent` interaction with BundleDeployments and Cluster objects also cause an impact on the controller
  -> related to fake-agent new issue
- gitrepos vs. bundle
  - Bundles are easy to create directly
  - Creation of Bundle resources instead of GitRepos removes one indirection, since they are actually managed by the `gitjob` controller
- Explore how to extract data from Prometheus:
  - Use Prometheus Admin API to create snapshots?
    - Needs access to filesystem
  - (Ab)use Prometheus PushGateway?
    - Is it really able to hold metrics for so long? 
    - Prometheus does not allow out-of-order samples:
      - https://www.robustperception.io/debugging-out-of-order-samples/
  - Alternative, e.g. Grafana Mimir?
    - https://grafana.com/blog/2022/09/07/new-in-grafana-mimir-introducing-out-of-order-sample-ingestion/
  - [`mimirtool`](https://grafana.com/docs/mimir/latest/manage/tools/mimirtool/)?
    - `remote-read` and `backfill` commands?
- How to store data from Prometheus (while there is no long-term storage for the organization)
  - Git repositories? S3?
  - Include the start timestamp to ease alligning metrics with PromQL's `offset` 
- How to load stored data back into a new Prometheus

#### New issues

1. Create basic benchmark:
  - What test suite should execute? Probably E2E a good starting point?
  - to be run locally
  - Assume target is already setup, and accept a kubeconfig as input
    - Same starting point regardless of the target
  - Measurements:
    - CPU/Memory usage? Increment based on load?
    - Duration?
    - Boundary?
  - output?
    - summary/table with main figures, extracted from prometheus queries?
    - starting timestamp
    - grafana dashboard snapshots?
    - prometheus backups/snapshots? how?

2. Setup upstream cluster on public cloud:
  - Preferably using some cloud templating system, maybe Terraform?
  - Are existing AKS/EKS GitHub CI workflows enough?
  - Install fleet + monitoring

3. Setup downstream cluster and register
  - Same approach than upstream cluster but difference specs/ installed packages

4. Fake agent to simulate downstream cluster behavior
  - Consumes target namespace:
    - Reads and updates BundleDeployment status, without really deploying anything
    - Update `Cluster` object with overall status
  - Fake, does not need an actual cluster
  - Parameterizable to simulate delays, slow deployments, networking issues, etc.
  - **This development should be hold until we have a solid ground**, hence should be blocked on the above issues
    - The goal is to offer same results in benchmark than real clusters, so we need to obtain those results first
