#!/bin/bash
set -e

# parametros
N_AMOSTRAS=20 # numero de execucoes para cada tamanho de buffer
BUFFER_MAX=20 # tamanho maximo do buffer em potencia de 2

# funcoes
die() {
  echo -e "$@"; exit 1
}

run() {
  OUTFILE="./data/out_${1}.csv"
  echo "#tamanho_exp2,media_tempo" > $OUTFILE

  BUFFSIZE=1
  echo "Executando ${1}..."
  for (( i = 0; i <= $BUFFER_MAX; ++i )); do
    SOMA=0
    for (( j = 1; j <= $N_AMOSTRAS; ++j )); do
      # limpar caches de disco antes de executar
      eval "$CLEAR_CMD" # FIXME eval nao recomendado, usar solucao mais segura

      TEMPO=`(time (./bin/prog_${1} $BUFFSIZE < ./data/data_in > /dev/null)) 2>&1 | \
      xargs | cut -d' ' -f4,6 | sed -e 's/.m//g' -e 's/s//g' -e 's/ /+/g'`
      SOMA=`echo "$SOMA + $TEMPO" | bc`
    done

    SOMA=`echo "$SOMA / $N_AMOSTRAS" | bc -l`
    echo "$i,$SOMA" >> $OUTFILE
    echo -ne "${1} $((${i}+1))/$((${BUFFER_MAX}+1))\r"

    ((BUFFSIZE *= 2))
  done
  echo ""
}

plot() {
if [ $1 == "syscall" ]; then
  TITLE="Versão System Call"
  COLOR="#aa0e50"
else
  TITLE="Versão Lib C"
  COLOR="#516288"
fi

gnuplot << EndOfFile
  set datafile separator ","
  set title "$TITLE"
  set terminal svg enhanced size 500,500 background rgb 'white'

  set output "plot_${1}.svg"
  set bmargin 3
  set xlabel "Buffer (2^x)"
  set ylabel "Tempo (s)"
  set xtics 1
  set ytics 0.02
  set yrange [0:0.5]
  set style line 1 lc rgb '$COLOR' lt 1 lw 1 pt 7 ps 0.5
  set pointintervalbox 3
  set grid

  plot "./data/out_${1}.csv" with linespoints ls 1 notitle
EndOfFile
}

plot_comparacao() {
  COLOR_SYS="#aa0e50"
  COLOR_LIBC="#516288"

  gnuplot << EndOfFile
  set datafile separator ","
  set title "Comparação Sys x LibC"
  set terminal svg enhanced size 500,500 background rgb 'white'

  set output "plot_comparacao.svg"
  set bmargin 3
  set xlabel "Buffer (2^x)"
  set ylabel "Tempo (s)"
  set xtics 1
  set ytics 0.02
  set yrange [0:0.5]
  set pointintervalbox 3
  set grid

  set style line 1 lc rgb '$COLOR_SYS' lt 1 lw 1 pt 7 ps 0.5
  set style line 2 lc rgb '$COLOR_LIBC' lt 1 lw 1 pt 7 ps 0.5
  plot "./data/out_syscall.csv" with linespoints ls 1 t 'syscall',\
       "./data/out_glibc.csv"   with linespoints ls 2 t 'libc'
EndOfFile
}

# comeco do script
# ----------------
if [ $EUID -ne 0 ]; then
  type sudo > /dev/null 2>&1 || die "Execute o script como root ou instale sudo."
  CLEAR_CMD="sync; sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'"
else
  CLEAR_CMD="sync; echo 3 > /proc/sys/vm/drop_caches"
fi

type make > /dev/null 2>&1 || die "GNU make nao foi encontrado no PATH."
type bc > /dev/null 2>&1   || die "Calculadora bc nao foi encontrada no PATH."

[ -d ./bin ]               || mkdir bin
[ -d ./data ]              || mkdir data
[ -x ./bin/prog_syscall ]  || make prog_syscall
[ -x ./bin/prog_glibc ]    || make prog_glibc
[ -s ./data/data_in ]      || dd if=/dev/zero of=./data/data_in bs=1024 count=10K

if [[ $1 != "plot" ]];then
  run syscall
  run glibc
  echo -e "Execucao finalizada.\nOs resultados encontram-se em ./data"
fi

type gnuplot > /dev/null 2>&1 || \
die "GNU plot nao foi encontrado no PATH, nao sera possivel gerar os graficos \
dos resultados.\nExecute o script com './run_tests.sh plot' para tentar gerar \
apenas os graficos novamente."

plot syscall
plot glibc
plot_comparacao
# fim do script
# -------------
