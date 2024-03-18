# 開発者向け（自分用）メモ

以下の草稿及び実装内では，
Cross Reference のことを「レジスタ」と呼んでいる．[^1]

[^1]:
    これは単に作者（私）が間違えて覚えてしまい，その方が自分にとって自然になってしまったため．
    恐らく `register-cross-reference` から連想して間違えて覚えてしまったものと思われる．
    そのうち修正するかも知れないし，しないかも知れない．．．

## コンパイル方法など

satysfi-base を利用しているので，base のインストールが必要．
出来れば最新版を pin して活用した方が良さそう．

```bash
# 出来れば最新版を pin する．
# 最新版でないと直っていないバグがあったり仕様が少し変わっているため．
opam pin add "git+https://github.com/nyuichi/satysfi-base.git"
opam install satysfi-base
satyrographos install
```

レジスタを活用しまくるパッケージの開発にあたって，aux ファイルがあると挙動が変わることがある．
Aux ファイルはまずは削除して，コンパイルして望み通りの結果になるか確かめる必要がある．

```bash
rm sample.satysfi-aux; satysfi sample.saty | tee output.log
```

デバッグ用に継続的にコンパイルするために，
fswatch でファイルを監視する bash スクリプトを書いたので，
fswatch をインストール済みであれば以下のようにして使うこともできる．

```bash
./watch sample.saty
```

## 実装方針

本パッケージは，footnote を活用して図をページ下部に配置する．
図を footnote の最上部に配置するために，
本来の footnote は一旦退避させておき，
そのページの中の最後の図を挿入するタイミングで退避させた footnotes も挿入する．

今回使用しているレジスタは以下の三つ．
全てに prefix `__footnote-scheme-ext:` をつけている．

- `__footnote-scheme-ext:fig-map:<figure number>` → `<page number> <footnote-num>`
- `__footnote-scheme-ext:footnote-map:<footnote number>` → `<page number>`
- `__footnote-scheme-ext:fig-num` → `<maximum figure number>`

実装においては figure という名前にしているが，実際には float 環境を意味している．[^2]

実装の詳細．

- Figure には figure number と footnote number を両方振る．
- Figure を挿入しようとするときは hook-page-break で，
  その figure を挿入しようとしたページ番号を取得し，
  その figure の番号と footnote number とともにレジスタに記録する．
  - レジスタ: `__footnote-scheme-ext:fig-map:<figure number> ----> <page number> <footnote-num>`
- footnote を挿入しようとしているときも hook-page-break で，
  その footnote を挿入しようとしたページ番号を取得し，
  レジスタに記録する．
  - レジスタ: `__footnote-scheme-ext:footnote-map:<footnote number> ----> <page number>`
- 冒頭でレジスタから読み出してきて以下の関数を定義する．
  - (a) figure num が与えられたときにその figure がそのページで一番最後かを判定する関数．
    `is-last-fig: <figure number> -> bool`
    - レジスタ: `__footnote-scheme-ext:fig-map:<figure number> ----> <page number> <footnote-num>` を参照する．
    - 最初は全ての figure が自分が一番最後だと思うような実装にする．
      未定義の場合，default は常に true を返す．
  - (b) footnote num が与えられたときに，
    「これから挿入しようとしているページに figure がない，または既に全ての figure を挿入した後である」
    かを判定する関数を定義する．
    `is-no-more-fig: <footnote number> -> bool`
    - レジスタ `__footnote-scheme-ext:footnote-map:<footnote number> ----> <page number>` を参照する．
    - 最初は figure がないと思うような実装にする．
      未定義の場合，default は常に true を返す．
- figure が与えられたとき．
  - figure-num-ref から自分の figure num を取得．
  - この際，figure num の最大値をレジスタ `__footnote-scheme-ext:figure-num` に記録しておく．
  - 自分自身は普通に add-footnote していく．
  - `is-last-fig` を参照して，自分が一番最後なら footenotes-ref を flush する．
  - hook-page-break を行う（前述参照）
- footnote が与えられたとき．
  - footnote-num-ref から自分の footnote num を取得．
  - `is-no-more-fig` を参照して，
    true なら 普通に add-footnote していく．
    false なら footnote-ref に退避させる．
  - hook-page-break を行う（前述参照）

[^2]: 数値の float 型と紛らわしいと思ったため．

## ハマったこと

satysfi はレジスタの値が更新されている場合は全てを再評価するのではなく，
あくまで document のみ再評価するように見える．

従って，パッケージ側も再評価して欲しいなら，
initialize などの関数内で再評価して欲しい関数を呼び出しておいた上で，
その initialize などの関数をユーザにきちんと呼び出してもらうという運用にする必要がある．

## その他の失敗に終わった試みなど

FigBox モジュールを使って絶対座標で挿入する．
レジスタに footnote の高さを記録しておき，text-height をそれに応じて変える？
text-height は footnote も含んだ高さなので，やはり footnote の方が上に来てしまうか．

- figure の高さをレジスタに登録する．
- footnote の横線を描画する際に，その上に figure の分のスペースを空けておく．
- figure の座標は footnote の座標に合わせて配置する．
  footnote の横線を描画する際に，その座標をレジスタに記録しておく．
  これができなさそう．
  - hook で渡される point は恐らくその hook が呼び出されたポイント．
  - hook を呼び出して仕舞えば良いのでは？
    - ダメだった．
