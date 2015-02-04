#!/bin/sh

pushd /root

if [ -d "spark" ]; then
  echo "Spark seems to be installed. Exiting."
  return
fi

# TODO ensure set
#${HADOOP_VERSION:?}
HADOOP_VERSION=${HADOOP_VERSION-"2.4.1"}

if [ `python -c "print '$HADOOP_VERSION'.startswith('2.4')"` == "True" ]; then
  HADOOP_PROFILE="hadoop2.4"
else
  echo "Unknown hadoop profile. Exiting."
  return -1
fi


# Github tag:
if [[ "$SPARK_VERSION" == *\|* ]]
then

  # TODO find way of specifying Tachyon version in build via command line... probably not possible until they make it a property in their build.

  repo=`python -c "print '$SPARK_VERSION'.split('|')[0]"`
  git_hash=`python -c "print '$SPARK_VERSION'.split('|')[1]"`

  echo "Building Spark from $repo, hash: $git_hash against Hadoop $HADOOP_VERSION using profile $HADOOP_PROFILE"
  mkdir spark
  pushd spark
  git init
  git remote add origin $repo
  git fetch origin
  git checkout $git_hash
  export MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"
  # TODO need -Phadoop-provided ??
  # TODO mvn install ??
  # Note: this takes a over an hour on an m3.medium
  # TODO find way of selecting which modules to build, as we don't need all of them.
  mvn -Pyarn -P$HADOOP_PROFILE -Dhadoop.version=${HADOOP_VERSION} -DskipTests clean package
  popd

# Pre-packaged spark version:
else 

  echo "Getting pre-packaged Spark $SPARK_VERSION built against $HADOOP_PROFILE"
  wget http://s3.amazonaws.com/spark-related-packages/spark-$SPARK_VERSION-bin-$HADOOP_PROFILE.tgz

  echo "Unpacking Spark"
  tar xvzf spark-*.tgz > /tmp/spark-ec2_spark.log
  rm -f spark-*.tgz
  mv `ls -d spark-* | grep -v ec2` spark
fi

# Don't copy-dir if we're running this as part of image creation.
if [ -d "/root/spark-ec2" ]; then
  /root/spark-ec2/copy-dir /root/spark
fi

popd
