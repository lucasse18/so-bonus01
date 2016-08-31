#!/bin/bash
set -e

# parametros
N_AMOSTRAS=5  # numero de execucoes para cada tamanho de buffer
BUFFER_MAX=20 # tamanho maximo do buffer em potencia de 2

# funcoes
function run() {
  OUTFILE="./data/out_${1}.csv"
  echo "#tamanho_exp2,media_tempo" > $OUTFILE

  BUFFSIZE=1
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

function die() {
  echo "$@"; exit 1
}

function plot() {
INFILE="./data/out_${1}.csv"
if [ $1 == "syscall" ]; then
  TITLE="Versão System Call"
  COLOR="#aa0e50"
else
  TITLE="Versão GNU Lib C"
  COLOR="#516288"
fi
gnuplot << EndOfFile
  set datafile separator ","
  set title "$TITLE"
  set term "png"

  #stats "$INFILE" using 1 name "size"
  #stats "$INFILE" using 2 name "time"

  set output "plot_${1}.png"
  set bmargin 3
  set xlabel "Buffer (2^n)"
  set ylabel "Tempo (s)"
  set xtics 1
  set ytics 0.05
  set yrange [0:1]
  set style line 1 lc rgb '$COLOR' lt 1 lw 1 pt 7 ps 1
  set pointintervalbox 3

  plot "$INFILE" with linespoints ls 1 notitle
EndOfFile
}

# comeco do script
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
[ -s ./data/data_in ]      || dd if=/dev/zero if=./data_in bs=1024 count=10K

if [[ $1 != "plot" ]];then
  run syscall
  run glibc
fi

type gnuplot > /dev/null 2>&1 || \
  die "GNU plot nao foi encontrado no PATH, nao sera possivel gerar os graficos \
  dos resultados."

plot syscall
plot glibc

