#!/usr/bin/perl

# probe2seq：マイクロアレイのプローブIDを塩基配列に変換する
#
# 必要なモジュール：
# HTML::Template
# LWP::Simple
# JSON::XS
#
# 2013-07-29 Yuki Naito (@meso_cacase)

#- ▼ モジュール読み込みと変数の初期化
use warnings ;
use strict ;

eval 'use HTML::Template ; 1' or  # HTMLをテンプレート化
	print_txt('ERROR : cannot load HTML::Template') ;

eval 'use LWP::Simple ; 1' or     # SSD検索サーバとの接続に使用
	print_txt('ERROR : cannot load LWP::Simple') ;

eval 'use JSON::XS ; 1' or        # SSD検索サーバとの接続に使用
	print_txt('ERROR : cannot load JSON::XS') ;
#- ▲ モジュール読み込みと変数の初期化

#- ▼ リクエストからパラメータを取得
#-- ▽ 使用するパラメータ一覧
my $query_string = '' ;  # 検索クエリ: 1つまたは複数の検索ワード
my $format       = '' ;  # 出力フォーマット: html, txt, fasta, fa
my $download     = '' ;  # ファイルとしてダウンロードするか: (boolean)
#-- △ 使用するパラメータ一覧

#-- ▽ URIからパラメータを取得
# 例：/probe_id.fasta.download
#
my $request_uri = $ENV{'REQUEST_URI'} // '' ;
$request_uri =~ s/\?.*// ;  # '?' 以降のQUERY_STRING部分を除去

(my $query_string_tmp = $request_uri) =~ s{^/(probe2seq/)?(test/)?}{} ;
$query_string = url_decode($query_string_tmp) ;

if ($query_string =~ s/(?:\.(html|txt|fasta|fa)|\.(download))+$//i){
	$1 and $format   = lc $1 ;
	$2 and $download = 'true' ;
}
#-- △ URIからパラメータを取得

#-- ▽ QUERY_STRINGからパラメータを取得
my %query = get_query_parameters() ;    # HTTPリクエストからクエリを取得

$query_string =                         # 検索クエリ
	$query{'query'} //                  # 1) QUERY_STRINGから
	$query_string   //                  # 2) QUERY_STRING未指定 → URIから
	'' ;                                # 3) URI未指定 → 空欄
$query_string =~ s/^\s*(.*?)\s*$/$1/ ;  # 前後のスペースを除去

$format =                               # 出力フォーマット
	(defined $query{'format'} and $query{'format'} =~ /^(html|txt|fasta|fa)?$/i) ?
	lc($query{'format'}) :              # 1) QUERY_STRINGから
	$format //                          # 2) QUERY_STRING未指定 → URIから
	'' ;                                # 3) URI未指定 → 空欄

$download =                             # ファイルとしてダウンロードするか
	$query{'download'} //               # 1) QUERY_STRINGから
	$download          //               # 2) QUERY_STRING未指定 → URIから
	'' ;                                # 3) URI未指定 → 空欄
#-- △ QUERY_STRINGからパラメータを取得
#- ▲ リクエストからパラメータを取得

#- ▼ パラメータからURIを生成してリダイレクト
my $redirect_uri = '/' ;
$redirect_uri .= ($request_uri =~ m{^/(probe2seq/)?(test/)?}) ? "$1$2" : '' ;
$redirect_uri .= url_encode($query_string) ;
$redirect_uri .= $format   ? ".$format"  : '' ;
$redirect_uri .= $download ? '.download' : '' ;

if ($ENV{'HTTP_HOST'} and              # HTTP経由のリクエストで、かつ
	($request_uri ne $redirect_uri or  # 現在のURIと異なる場合にリダイレクト
	 $ENV{'QUERY_STRING'})
){
	redirect_page("http://$ENV{'HTTP_HOST'}$redirect_uri") ;
}
#- ▲ パラメータからURIを生成してリダイレクト

#- ▼ defaultパラメータ設定
$format   ||= 'html' ;
$download ||= '' ;
#- ▲ defaultパラメータ設定

#- ▼ トップページ表示
unless ($query_string){
	my $top = HTML::Template->new(filename => 'top.tmpl')->output ;
	print_html($top) ;
}
#- ▲ トップページ表示

#- ▼ 検索実行と表示
my @seqlist = arrayprobe2seq($query_string) ;

if ($format eq 'txt'){
	map {s/^.*\t//} @seqlist ;
	my $seqlist_txt = join "\n", @seqlist ;
	print_txt($seqlist_txt) ;
} elsif ($format eq 'fasta' or $format eq 'fa'){
	map {s/^(.*)\t(.*)$/>$1\n$2/} @seqlist ;
	my $seqlist_fasta = join "\n", @seqlist ;
	print_txt($seqlist_fasta) ;
} else {
	map {s/^.*\t//} @seqlist ;
	my $seqlist_txt = join "\n", @seqlist ;
	my $seqlist_html = 
	"<p>Result:</p>\n" .
	"<textarea rows=20 cols=80>$seqlist_txt\n" .
	'</textarea>' ;
	print_html($seqlist_html, $query_string) ;
}
#- ▲ 検索実行と表示

exit ;

# ====================
sub get_query_parameters {  # CGIが受け取ったパラメータの処理
my $buffer = '' ;
if (defined $ENV{'REQUEST_METHOD'} and
	$ENV{'REQUEST_METHOD'} eq 'POST' and
	defined $ENV{'CONTENT_LENGTH'}
){
	eval 'read(STDIN, $buffer, $ENV{"CONTENT_LENGTH"})' or
		print_txt('ERROR : get_query_parameters() : read failed') ;
} elsif (defined $ENV{'QUERY_STRING'}){
	$buffer = $ENV{'QUERY_STRING'} ;
}
my %query ;
my @query = split /&/, $buffer ;
foreach (@query){
	my ($name, $value) = split /=/ ;
	if (defined $name and defined $value){
		$value =~ tr/+/ / ;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/eg ;
		$name  =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/eg ;
		$query{lc($name)} = $value ;
	}
}
return %query ;
} ;
# ====================
sub url_decode {  # URLデコード
my $str = $_[0] or return '' ;
$str =~ s/%([0-9A-F]{2})/pack('C', hex($1))/ieg ;
$str =~ tr/+/ / ;
return $str ;
} ;
# ====================
sub url_encode {  # URLエンコード
my $str = $_[0] or return '' ;
$str =~ s/([^\w\-\.\_\~\ ])/'%' . unpack('H2', $1)/eg ;
$str =~ tr/ /+/ ;
return $str ;
} ;
# ====================
sub redirect_page {  # リダイレクトする
my $uri = $_[0] // '' ;
print "Location: $uri\n\n" ;
exit ;
} ;
# ====================
sub escape_sedueq {  # 「&[]|-\()?:」をエスケープする
my $str = $_[0] // '' ;
$str =~ s/&/%5c%26/g ;
$str =~ s/\[/%5b/g ;
$str =~ s/\]/%5d/g ;
$str =~ s/(?=[\|\-\\\(\)\?\:])/\\/g ;
return $str ;
} ;
# ====================
sub arrayprobe2seq {  # マイクロアレイのprobe IDを塩基配列に変換
my $probeid  = $_[0] or return () ;
my $q        = escape_sedueq(lc($probeid)) ;
my $host     = '172.18.8.70' ;  # ssd.dbcls.jp (SSD検索サーバ)
my $port     = '7700' ;
my $instance = 'arrayprsub' ;
my $uri      = "http://$host:$port/v1/$instance/query?" .
               "q=(probeid_norm:exact:$q)?to=50?get=probeid_orig,targetseq&format=json" ;
my $json     = get($uri) or print_txt('ERROR : cannot connect to searcher') ;
my $hit      = decode_json($json) // '' ;
my @probeseq ;
if ($hit->{hit_num}){  # ヒットする場合のみ変換を実行
	foreach (@{$hit->{docs}}){
		my $probeid_orig = $_->{fields}->{probeid_orig} ;
		my $targetseq    = $_->{fields}->{targetseq} ;
		$targetseq and push @probeseq, "$probeid_orig	$targetseq" ;
	}
	return @probeseq ;
} else {
	return ('Not found.') ;
}
} ;
# ====================
sub print_txt {  # TXTを出力
my $txt = $_[0] // 'ERROR : query is empty' ;

print "Content-type: text/plain; charset=utf-8\n" ;
print "Content-Disposition: attachment; filename=probeseq.txt\n"
	if $download ;
print "\n$txt\n" ;

exit ;
} ;
# ====================
sub print_html {  # HTMLを出力
my $html  = $_[0] // '' ;
my $query = $_[1] // '' ;
my $index = HTML::Template->new(filename => 'index.tmpl') ;
$index->param(HTML => $html, Q => $query) ;

print "Content-type: text/html; charset=utf-8\n\n" ;
print $index->output ;

exit ;
} ;
# ====================
