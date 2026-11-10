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
