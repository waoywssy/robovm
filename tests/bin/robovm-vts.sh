#!/bin/bash

export HOME=$(cd ~; pwd)

BASE=$(cd $(dirname $0)/../..; pwd -P)
if [ -f "$BASE/tests/bin/robovm-vts.env" ]; then
  . $BASE/tests/bin/robovm-vts.env
fi
[ "x$COMPILER_JAR" == 'x' ] && COMPILER_JAR=$(ls $BASE/compiler/target/robovm-compiler-*.jar 2> /dev/null)
if [ "x$COMPILER_JAR" == 'x' ]; then
  echo "robovm-compiler-*.jar file not found in path $BASE/compiler/target/"
  exit 1
fi
[ "x$ARCH" == 'x' ] && ARCH=auto
[ "x$TARGET" == 'x' ] && TARGET=/tmp/robovm-vts.$ARCH

export PATH

mkdir -p $HOME/.robovm/vts/

n=0
while [ ${1:0:1} = '-' ]; do
  if [ "$1" = '-cp' ]; then
    shift
    parts=$(echo $1 | tr ':' '\n')
    for p in $parts; do
      if [ -d "$p" ]; then
        JAR=$HOME/.robovm/vts/vts$n.jar
        if [ ! -f "$JAR" ]; then
          jar cf $JAR -C "$p" .
        fi
        CP=$(test "x$CP" = "x" && echo "$JAR" || echo "$CP:$JAR")
        n=$((n + 1))
      elif [ -f "$p" ]; then
        CP=$(test "x$CP" = "x" && echo "$p" || echo "$CP:$p")
      fi
    done
  fi
  shift
done

MAINCLASS=$1
shift

while [ "x$1" != 'x' ]; do
  RUNARGS="$RUNARGS $1"
  shift
done

#echo "ARGS=$ARGS"
#echo "RUNARGS=$RUNARGS"
#echo "MAINCLASS=$MAINCLASS"

if [ ! -x $TARGET/vts ]; then
  ROBOVM_DEV_ROOT=$BASE java \
    -XX:+HeapDumpOnOutOfMemoryError \
    -Xmx1024m \
    -Xss1024k \
    -jar $COMPILER_JAR \
    -tmp /tmp/robovm-vts.tmp \
    -d $TARGET \
    -arch $ARCH \
    -o vts \
    -debug \
    -verbose \
    -cp $CP
fi

LIBPATH=$TARGET
if [ "x$LD_LIBRARY_PATH" != 'x' ]; then
  LIBPATH=$LIBPATH:$LD_LIBRARY_PATH
fi
if [ "x$DYLD_LIBRARY_PATH" != 'x' ]; then
  LIBPATH=$LIBPATH:$DYLD_LIBRARY_PATH
fi

LD_LIBRARY_PATH=$LIBPATH DYLD_LIBRARY_PATH=$LIBPATH $TARGET/vts -rvm:MainClass=$MAINCLASS $RUNARGS
CODE=$?
exit $CODE

