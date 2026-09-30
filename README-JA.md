# VolumeBoost500

iPhone向けのWebViewブラウザ型ボリュームブースターです。

- 起動時に https://asmr.one を表示
- Web Audio API の GainNode で0〜500%を制御
- 100%=1.0 / 200%=2.0 / 300%=3.0 / 400%=4.0 / 500%=5.0
- 画面下部に半透明のボリュームスライダーを表示
- GitHub Actions の macOS runner でiOS向けビルドを実行

## ビルド

GitHub Actions の「Build VolumeBoost500」を手動実行してください。
生成されたIPAはArtifactsから取得できます。

> IPAはコード署名を行わないビルドです。AltStore等で自分のApple Accountを使って再署名してインストールする用途を想定しています。
