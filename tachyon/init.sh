#!/bin/sh

pushd /root

if [ -d "tachyon" ]; then
  echo "Tachyon seems to be installed. Exiting."
  return 0
fi

TACHYON_VERSION=${TACHYON_VERSION-"git://github.com/amplab/tachyon.git|tags/v0.5.0"}

# Github tag:
if [[ "$TACHYON_VERSION" == *\|* ]]
then

  # TODO ensure set
  #${HADOOP_VERSION:?}
  HADOOP_VERSION=${HADOOP_VERSION-"2.4.1"}

  repo=`python -c "print '$TACHYON_VERSION'.split('|')[0]"`
  git_hash=`python -c "print '$TACHYON_VERSION'.split('|')[1]"`

  # See http://tachyon-project.org/master/Building-Tachyon-Master-Branch.html
  echo "Building Tachyon from $repo, hash $git_hash against Hadoop ${HADOOP_VERSION}..."

  #git clone git://github.com/amplab/tachyon.git
  #cd tachyon
  #git checkout tags/v$TACHYON_VERSION

  mkdir tachyon
  pushd tachyon
  git init
  git remote add origin $repo
  git fetch origin
  git checkout $git_hash

  wget "http://archive.apache.org/dist/maven/maven-3/3.2.3/binaries/apache-maven-3.2.3-bin.tar.gz"
  tar xvzf apache-maven-3.2.3-bin.tar.gz
  rm -rf /opt/apache-maven-3.2.3/
  mv apache-maven-3.2.3 /opt/

  # Edit bash profile
  echo "export PS1=\"\\u@\\h \\W]\\$ \"" >> ~/.bash_profile
  echo "export JAVA_HOME=/usr/lib/jvm/java-1.7.0" >> ~/.bash_profile
  echo "export M2_HOME=/opt/apache-maven-3.2.3" >> ~/.bash_profile
  echo "export PATH=\$PATH:\$M2_HOME/bin" >> ~/.bash_profile

  source ~/.bash_profile


  mvn -Dhadoop.version=${HADOOP_VERSION} -DskipTests clean install

# Pre-package tachyon version
else

  echo "Getting pre-packaged Tachyon $TACHYON_VERSION"
  echo "WARNING: hadoop dependency is unsupported!"

  wget https://s3.amazonaws.com/Tachyon/tachyon-$TACHYON_VERSION-bin.tar.gz

  echo "Unpacking Tachyon"
  tar xvzf tachyon-*.tar.gz > /tmp/spark-ec2_tachyon.log
  rm -f tachyon-*.tar.gz
  mv `ls -d tachyon-*` tachyon
fi

# Don't copy-dir if we're running this as part of image creation.
if [ -d "/root/spark-ec2" ]; then
  /root/spark-ec2/copy-dir /root/tachyon
fi

popd
