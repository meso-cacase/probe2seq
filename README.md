Probe Search
======================

マイクロアレイのプローブIDを塩基配列に変換します。

+ http://probe.dbcls.jp/  
  本レポジトリにあるCGIが実際に稼働しています。


サンプル画像
-----

![スクリーンショット]
(http://g86.dbcls.jp/~meso/meme/wp-content/uploads/2013/09/probe2seq.png
"スクリーンショット")


API
--------

下記の変数を設定し ./ に POST または GET すると結果を取得できます。

+ *query* (省略不可)  
  マイクロアレイのプローブID。

+ *format* (省略可)  
  設計結果のフォーマット。  
  html  : HTML（省略時のデフォルト)  
  txt   : テキスト  
  fasta (or fa) : FASTA

+ *download* (省略可)  
検索結果をファイルとしてダウンロード (txt, fastaのみ)

または、下記のURIから同じ結果を取得できます。

+ URI: http://probe.dbcls.jp/query[.format][.download]


更新履歴
--------

### 2013年9月12日 ###

+ Probe Searchをリリース。
+ Agilentのプローブを収録して本サービスを公開。


ライセンス
--------

Copyright (c) 2013 Yuki Naito
 ([@meso_cacase](http://twitter.com/meso_cacase))  
This software is distributed under [modified BSD license]
 (http://www.opensource.org/licenses/bsd-license.php).  
Probe sequences presented on this site may be owned and  
 copyrighted by the manufacturers.
