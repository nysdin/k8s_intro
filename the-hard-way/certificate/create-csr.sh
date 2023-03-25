# kubernetes の各コンポーネントで必要となる CSR の入力ファイルを作成する。
# 出力された json ファイルを元に cfssl コマンドで CSR を作成

# jsonnet --help
## -m / --multi <dir>      Write multiple files to the directory, list files on stdout
jsonnet csr.jsonnet -m .
