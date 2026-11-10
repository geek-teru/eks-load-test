# eks-load-test

EKS（Fargate）+ Locust で負荷試験の環境を構築する。

## 概要

![EKS の全体像](docs/images/eks-overview.drawio.png)

- **コントロールプレーン（AWS 管理）**: EKS の API サーバーと Argo CD（EKS Capabilities）。エンドポイントはプライベートのみで、`kubectl` は VPC 環境の CloudShell から実行する
- **データプレーン（Fargate）**: ワーカーノード（EC2）は置かず、Fargate プロファイルの対象 namespace の Pod を Fargate で動かす
- **Argo CD**: GitHub のマニフェストをクラスタへ同期する。UI へのログインは IAM Identity Center（`argocd-admins` グループが ADMIN）
- **Locust**: master / worker を Fargate で分散実行し、クラスタの外にある公開済みのアプリへ負荷をかける（構築予定）
- dev は使うときだけ GitHub Actions で apply し、終わったら destroy する

## 構成

| 置き場所 | 管理方法 | 中身 |
| --- | --- | --- |
| `terraform/modules/eks-cluster` | Terraform | クラスタ本体、管理者のアクセスエントリ、アドオン（vpc-cni / kube-proxy） |
| `terraform/modules/eks-fargate` | Terraform | Fargate プロファイル、Pod 実行ロール、CoreDNS |
| `terraform/modules/eks-argocd` | Terraform | Argo CD の capability、ロール、アクセスポリシー |
| `k8s/argocd` | `kubectl apply`（CloudShell） | Argo CD に登録するもの（クラスタの Secret、Application） |
| `k8s/locust` | Argo CD が同期 | Locust の manifest（Kustomize） |
| `terraform/environments/<env>` | GitHub Actions（plan / apply / destroy） | 環境ごとのモジュールの呼び出し |

## GitOps（manifest の運用）

- `k8s/locust/` の変更は main へ push すると、Argo CD（Application `locust`）が自動で同期する。差分は Argo CD の画面で見られる
- Application は自動同期（prune・selfHeal あり）。`kubectl` で直接変えたものは Argo CD に戻される。変更は必ず Git 経由で行う
- `k8s/argocd/` は Argo CD 自身に登録するものなので同期の対象外。手で `kubectl apply` する

### クラスタを apply し直したあとの手順

クラスタを作り直すと Argo CD の登録も消えるため、VPC 環境の CloudShell から次の順に実行する（リポジトリを clone しておく）。

1. クラスタの登録（ARN はコミットしないため、実行時に置き換える）

   ```sh
   CLUSTER_ARN=$(aws eks describe-cluster --name dev-eks-load-test --query cluster.arn --output text)
   sed "s|CLUSTER_ARN|${CLUSTER_ARN}|" k8s/argocd/cluster-in-cluster.yaml | kubectl apply -f -
   ```

2. Application（locust）の登録

   ```sh
   kubectl apply -f k8s/argocd/locust.yaml
   ```

3. Argo CD の画面で `locust` が Synced / Healthy になり、`locust` namespace ができていることを確かめる

Argo CD の前提（Identity Center、`argocd-admins`）と UI の URL の確かめ方は、Argo CD の destroy / apply 手順に寄せる（ここでは重複して書かない）。

VPC は terraform-aws-cmn-vpc、Identity Center は terraform-aws-cmn-sso で管理しており、このリポジトリからは参照するだけ。

図は draw.io の XML を埋め込んだ PNG なので、draw.io（VSCode 拡張を含む）でそのまま開いて編集できる。

## dev の立ち上げと片付け

dev は使うときだけ立てる。クラスタごと消すので、Argo CD の capability も、クラスタの登録などの k8s リソースも destroy で一緒に消える。

### 前提

- Identity Center（terraform-aws-cmn-sso で管理）に `argocd-admins` グループがあること。無いと apply が失敗する
- Argo CD の UI を使うユーザーが `argocd-admins` グループに入っていること
- `kubectl` を実行する CloudShell（VPC 環境）に、クラスタ管理者の IAM ユーザー（Secrets Manager の `cluster_admin_principal_arns`）で入れること

### 立ち上げ

1. GitHub Actions の `terraform-apply` を `main` で、environment を `dev` にして実行する（15〜30 分ほど）。完了した時点で capability は `ACTIVE` になっている
2. CloudShell で kubeconfig を作り、自クラスタを Argo CD に登録する。クラスタの登録は destroy で消えるので、立ち上げのたびに行う

   ```bash
   aws eks update-kubeconfig --name dev-eks-load-test --region ap-northeast-1
   CLUSTER_ARN=$(aws eks describe-cluster --name dev-eks-load-test --query cluster.arn --output text)
   sed "s|CLUSTER_ARN|${CLUSTER_ARN}|" k8s/argocd/cluster-in-cluster.yaml | kubectl apply -f -
   ```

3. Argo CD の UI を開き、Identity Center のユーザーでログインする

### UI の URL の確かめ方

次のどちらかで確かめる。`terraform-apply` のログの output（`argocd_server_url`）にも出るが、アカウント ID が `***` にマスクされるので、そのままでは開けない。

- EKS コンソールでクラスタを開き、Capabilities の Argo CD から「Open Argo CD UI」を押す
- AWS CLI で取得する

  ```bash
  aws eks describe-capability --region ap-northeast-1 --cluster-name dev-eks-load-test \
    --capability-name dev-eks-load-test-argocd \
    --query 'capability.configuration.argoCd.serverUrl' --output text
  ```

### 片付け

使い終わったら `terraform-destroy` を `main` で、environment を `dev` にして実行する（6 分ほど）。

### 料金の注意

Argo CD の capability は、動かしている間ずっと時間課金される。Application がなくても capability の分はかかり、Application があるとその数に応じた時間課金が加わる。EKS クラスタの料金も別にかかるので、使い終わったら destroy する。単価は [Amazon EKS の料金](https://aws.amazon.com/eks/pricing/)を見る。

## 負荷試験の実施

Locust は Web UI から手動で動かす。UI に認証が無いため外には出さず、CloudShell（VPC 環境）から `port-forward` で入る。dev を立ち上げ、Argo CD で `locust` が Synced / Healthy になってから行う。

### 試験の前に

- 対象の URL は `k8s/locust/kustomization.yaml` の `locust-config` の `LOCUST_HOST` で決まる。変えるときは書き換えて main へ push する（Argo CD が同期し、Pod が入れ替わる）
- 対象は自分が管理する公開済みのアプリだけにする。ホスティング先の規約で負荷試験が許されているかを先に確かめる
- 初回はユーザー数を小さく（例: 10 ユーザー、spawn rate 1）、数分で止める

Pod が揃っているかを確かめる（master 1 台、worker は `replicas` の台数）。

```bash
kubectl -n locust get pods
```

### Web UI を開く

```bash
kubectl -n locust port-forward svc/locust-master 8089:8089
```

ブラウザで `http://localhost:8089` を開き、WORKERS が worker の台数になっていることを確かめる。Number of users と Ramp up（spawn rate）を入れて START を押し、数分たったら STOP を押す。

### ブラウザで開けない場合（curl で UI の API を叩く）

CloudShell では port-forward したポートをブラウザで開けないことがある。そのときは、port-forward をバックグラウンドで動かし、同じ CloudShell から curl で操作する。

```bash
kubectl -n locust port-forward svc/locust-master 8089:8089 >/dev/null 2>&1 &
U=http://localhost:8089

# 状態と worker の台数（ready / running / stopped）
curl -s $U/stats/requests | jq '{state, workers: (.workers | length), user_count}'

# 開始（対象は LOCUST_HOST。ユーザー数と spawn rate を指定する）
curl -s -X POST $U/swarm -d user_count=10 -d spawn_rate=1

# 途中経過
curl -s $U/stats/requests | jq '.stats[] | {name, num_requests, num_failures, avg_response_time}'

# 停止（POST で呼ぶ）
curl -s -X POST $U/stop
```

### シナリオを足す・切り替える

シナリオ（locustfile）は `k8s/locust/scenarios/` に1ファイル1シナリオで置き、`locust-scenarios` の ConfigMap にすべて入れる。どれを使うかは `locust-config` の `LOCUST_LOCUSTFILE` の1行で選ぶ。

1. `k8s/locust/scenarios/<名前>.py` を作る
   - ファイル先頭のコメントに、何を確かめるシナリオか・想定する負荷を書く
   - 対象のホストは書かない（`HttpUser` の `host` を指定しない）。`LOCUST_HOST` の値が使われる
   - パスは `self.client.get("/items")` のようにホストからの相対で書く
2. `k8s/locust/kustomization.yaml` の `locust-scenarios` の `files` に `<名前>.py=scenarios/<名前>.py` を足す（キー名 = ファイル名。`/mnt/locust/<名前>.py` にマウントされる）
3. 使うときは `locust-config` の `LOCUST_LOCUSTFILE` を `/mnt/locust/<名前>.py` に書き換える
4. main へ push する。ConfigMap の名前のハッシュが変わるので、Argo CD が同期すると master / worker が新しいシナリオで入れ替わる

push する前に、手元で ConfigMap に入っているかを確かめられる。

```bash
kubectl kustomize k8s/locust | grep -E 'LOCUST_LOCUSTFILE|^  [a-z0-9_-]+\.py: '
```

切り替わったかは、Pod が入れ替わったこと（`kubectl -n locust get pods` の AGE）と、Web UI の統計に出るリクエストの名前（パス）で確かめる。

### 対象 URL と UI の初期値を変える

`k8s/locust/kustomization.yaml` の `locust-config` で変えて main へ push する。

| 項目 | 内容 |
| --- | --- |
| `LOCUST_HOST` | 対象アプリの URL。シナリオを変えずに別のアプリへ向けられる |
| `LOCUST_USERS` | Web UI の Number of users の初期値 |
| `LOCUST_SPAWN_RATE` | Web UI の Ramp up（spawn rate）の初期値 |

`LOCUST_USERS` / `LOCUST_SPAWN_RATE` は初期値なので、UI（または curl の `/swarm`）で開始するときに上書きできる。

### 結果（CSV）の取り出し

結果は手元に保存し、リポジトリには置かない。止めたあと、次の試験を始める前に取り出す（START し直すと集計が消える）。

- ブラウザで開けた場合: UI の DOWNLOAD DATA から、Statistics・Failures・Exceptions の CSV と HTML のレポートをダウンロードする
- curl の場合: CloudShell に保存してから、CloudShell の「アクション」→「ファイルのダウンロード」で手元に落とす

  ```bash
  D=locust-$(date +%Y%m%d-%H%M)
  mkdir -p $D
  curl -s -o $D/stats.csv      $U/stats/requests/csv
  curl -s -o $D/failures.csv   $U/stats/failures/csv
  curl -s -o $D/exceptions.csv $U/exceptions/csv
  curl -s -o $D/report.html    $U/stats/report
  zip -r $D.zip $D
  ```

### worker の台数を変える

`k8s/locust/kustomization.yaml` の `replicas`（`name: locust-worker`）の `count` を 5〜15 の範囲で変えて main へ push する。`kubectl scale` は Argo CD の selfHeal で戻されるので使わない。Fargate は Pod ごとに起動に 30〜60 秒かかるので、UI の WORKERS が揃ってから始める。

### 終わったら

試験が終わったら、「dev の立ち上げと片付け」の「片付け」のとおり `terraform-destroy` で dev を落とす。
