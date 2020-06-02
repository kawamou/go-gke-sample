# go-gke-study
## はじめに
- GKE使うなら普通のPaaS使う感覚で使えそうな気もするしやっていき
## k8sってしんどいの？
[Kubernetes は辛いのか？](https://amsy810.hateblo.jp/entry/2019/04/03/071858)
>アプリケーション開発者として Kubernetes を利用するだけなら実際は非常にシンプルに利用することが可能です。
>マネージド Kubernetes を使えるなら、開発者として利用するだけなのでそこまで難しくありません。
## k8sの概念
>Kubernetesはいくつかのサーバーを組み合わせて、一つのクラスタリングを構築します。そのため、アプリケーションを実行する際にサーバー先を意識する必要はありません
- ただのGCEインスタンスを複数組み合わせてひとつの大きなクラスタを形成する。あるコンテナがNode AにデプロイされているかNode Bにデプロイされているかは利用者からは何も関係ない。クラスタが単一のコンピュータリソースとして振る舞うよう、k8sが管理を行う
- Masterがクラスタの管理を担う。GKE等だとフルマネージドなので超絶ラク
- ***GKE等のマネージドk8sを使うなら、使用感は他のPaaSと何ら変わらない。作りたいアプリケーション考える。コンテナに固める。k8sクラスタにコンテナあげる。後はよしなに面倒みてもらえる***
## 用語集
- kubectl
  - k8sを操作するためのコマンドラインツール
- Node
  - コンテナを配置するためのサーバ。クラスタとして管理される。GCPでいえばGCEインスタンス
- Pod
  - デプロイの単位。コンテナひとつでもPodとしてデプロイ。密結合な場合は複数コンテナをPodとして束ねてデプロイ
  - Podにはそれぞれk8s内で固有の仮想IPアドレスが割り振られるようになっている。Podに所属するコンテナは全て同一のIPアドレス。なのでlocakhost:port名でPod内通信できるし、IPアドレスを指定すればPod間通信できる
- ReplicaSet
  - あるPodを何個デプロイするかの設定。可用性が高められる？
- Deployment
  - アプリケーションのスケーリングやバージョンを管理する。具体的にはReplicaSetを内部に記述する。yamlファイルを直接編集しkubectlで再デプロイすると、よしなにローリングアップデートとかしてくれる。古い方のPodが減り、新しい方のPodが増える
- Service
  - ReplicaSetへのロードバランサみたいな役割。ReplicaSet(Pod群)へリクエストを割り振る
  - ClusterIP：k8s内から利用可能な内部IP+portを作る。あるPodからあるPod群へアクセスする際に利用
  - NodePort：各Nodeにグローバルなportをあける。k8sの外からアクセスする際に利用
  - LoadBalancer：NodePortは各Nodeに穴をあけるだけ。LoadBalancerはNodePort+各パブリッククラウドのLBの組み合わせ。各Nodeへの負荷分散が可能。パブリッククラウドにのみ備わってるService
- Ingress
  - ロードバランサ。ServiceのLoadBalancerはL4のLB。IngressはL7のLBなのでNodeへのルーティングをパスベース等で行える！実際の利用時にはLBよりIngressを使う場合が多い？(要検証)
- Helm
  - KubernetesをKernelとみなすと複数のNodeインスタンスを束ねたClusterは１つのコンピューター、その上で動くコンテナはプロセスとみなすことができる。このような視点で考えると、HelmはCentOSにおけるYUM，DebianにおけるAPTと同様の役割を果たす
## 本k8sの構成
- ingressでhttp受け取ってnginxのservice(NodePort)で受け取る。nginxはproxy_passでgoのservice(ClusterIP)を指定。goがレスポンス返す
- 全体イメージ(メモ)
![K8S 001](https://user-images.githubusercontent.com/18514782/82153055-27508880-98a0-11ea-96aa-69af656362a5.png)
## 使い方
### セットアップ
```
# kubectl入ってるか確認
❯ kubectl version
# 無ければ
❯ gcloud components install kubectl
```
### dockerイメージ作り
- GCP上でContainer Registry APIを有効化
```
# Dockerfileあるディレクトリで実行
❯ docker build -t [IMAGE_NAME]:[TAG_NAME] .
# 確認
❯ docker run [IMAGE_NAME]:[TAG_NAME]
# GCP Container Registry使う準備
# docker push/pull時にGCR指定されてると自動でgcloudで認証するための準備↓
❯ gcloud auth configure-docker
# タグ付け
❯ docker tag [IMAGE_NAME]:[TAG_NAME] gcr.io/[PROJECT_NAME]/[IMAGE_NAME]:[TAG_NAME]
# PUSH
❯ docker push gcr.io/[PROJECT_NAME]/[IMAGE_NAME]:[TAG_NAME]
# ここまでやればGCR上でイメージ確認できる
```
### k8s周り
- GCP上でKubernetes Engine APIを有効化
```
# gcloudコマンドの度に--region指定しても良いんだが面倒なので設定しておく
❯ gcloud config set compute/zone asia-northeast1-a
# クラスタ作る。これがひとつの計算リソースになる
❯ gcloud container clusters create [CLUSTER_NAME] \
  --machine-type=n1-standard-1 \
  --num-nodes=2
# 下記コマンドによりkubectlから接続可能に
❯ gcloud container clusters get-credentials [CLUSTER_NAME] --zone asia-northeast1-a --project [PROJECT_NAME]
# 確認
❯ kubectl config get-contexts
# デプロイ
❯ kubectl apply -f [MANIFEST_YAML_FILE_NAME]
# k8sディレクトリ直下の複数ファイルを一気に読み込むことも可能
❯ kubectl apply -f k8s/
# クラスタ後片付け
❯ gcloud container clusters delete [CLUSTER_NAME]
# デバッグ周りのコマンド
# Pod名確認
❯ kubectl get pods
# Podに入る
❯ kubectl exec -it [POD_NAME] /bin/sh
# Pod詳細確認
kubectl describe pod [POD_NAME]
```
## YAML
### 基本的な書き方
```
apiVersion: v1 # どのバージョンのKubernetesAPIを使いオブジェクトを作成するか宣言
kind: Service # 作成するオブジェクトの種類
metadata:
  name: go-service # 作成するオブジェクトの名前
spec:
  type: ClusterIP # Serviceの種類。ClusterIP, NodePort等
  ports:
    - protocol: "TCP"
      port: 8080 # Serviceが受け取るport番号
      targetPort: 8080 # Podのport番号
  selector:
    app: go # ラベルが"app: go"のPodにリクエストを送る
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-deployment
spec:
  replicas: 2 # ReplicaSetの個数。最低維持するPod数
  selector:
    matchLabels:
        app: go
  template: # Podのテンプレート
    metadata:
      labels:
        app: go
    spec:
      containers: # Podに属するコンテナのリスト(今回はひとつだけ)
      - name: go-container
        image: gcr.io/[PROJECT_NAME]/[IMAGE_NAME]
        imagePullPolicy: Always
```
### 今回のYAMLのポイント
- ingress.yml：Ingressの定義
- nginx.yml：nginxのService(NodePort)とnginxのDeproymentを定義
- configmap.yml：素のnginxイメージにnginx.conf反映させたい。でもそのために自前のイメージ作るの面倒。configmapに書いたものをnginxコンテナのvolumeにマウントする
- go-app.yml：goのService(ClusterIP)とgoのDeproymentを定義
## メモ
- GKEのIngressではヘルスチェックのためにデフォルトでGET / へリクエストを送信し、ステータスコード200が返ってくることを期待している。当初 / へのリクエストに対するレスポンスをgo側で考慮してなかったので、200を返せずingressが立ち上がらなかった
- k8sの今後について
```
### インフラエンジニアの課題意識
・構成管理
・リソースモニタリング
・HW障害から復旧
・デプロイの簡素化
k8sは上記の課題をすべて解決するOSSツール。
フルスタックなので他にインストール不要なのも便利。
```
## 参考
- [GKEにGoのアプリケーションをデプロイする](https://qiita.com/keitakn/items/241ccd2bc95c2c879735)
- [Kubernetes実践入門。基本的なyamlとコマンドから学ぶサービス運用効率化術](https://flxy.jp/article/10107)
- [Kubernetes NodePort vs LoadBalancer vs Ingress? When should I use what? (Kubernetes NodePort と LoadBalancer と Ingress のどれを使うべきか) を訳した](http://chidakiyo.hatenablog.com/entry/2018/09/10/Kubernetes_NodePort_vs_LoadBalancer_vs_Ingress%3F_When_should_I_use_what%3F_%28Kubernetes_NodePort_%E3%81%A8_LoadBalancer_%E3%81%A8_Ingress_%E3%81%AE%E3%81%A9%E3%82%8C%E3%82%92%E4%BD%BF%E3%81%86)
- [kubernetesで動かすソフトウェアの設定をConfigMapで記述する](https://qiita.com/petitviolet/items/ee4b1bdba2670a1d6a12)
