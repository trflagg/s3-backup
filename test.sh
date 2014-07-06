#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)

if [[ -z $BUCKET_NAME ]]
then
  echo "You need to specify a BUCKET_NAME env variable"
  exit 1
fi
if [[ -z $REMOTE_PATH ]]
then
  echo "You need to specify a REMOTE_PATH env variable"
  exit 1
fi

pushd backup
sudo docker build -t trflagg/s3-backup .
popd

pushd restore
sudo docker build -t trflagg/s3-restore .
popd

function cleanup {
  echo "Cleaning up"
  ids_to_kill=$(sudo docker ps -a | grep s3-backup-test | awk '{ print $1 }')
  for id in $ids_to_kill
  do
    sudo docker stop $id || true
    sudo docker rm $id
  done
}

cleanup

# create a data container
sudo docker run --name s3-backup-test-data-original --volume /var/s3-backup busybox true

# write some data to the container
sudo docker run --name s3-backup-test-writer --rm --volumes-from s3-backup-test-data-original busybox sh -c 'echo "test data" > /var/s3-backup/test'

# do a backup
sudo docker run --rm --name s3-backup-test-backup --volume ~/.boto:/etc/boto.cfg --volumes-from s3-backup-test-data-original trflagg/s3-backup -s /var/s3-backup -b $BUCKET_NAME -r $REMOTE_PATH

# create a new data container
sudo docker run --name s3-backup-test-data-restore --volume /var/s3-backup busybox true

# do a restore
sudo docker run --rm --name s3-backup-test-store --volume ~/.boto:/etc/boto.cfg --volumes-from s3-backup-test-data-restore trflagg/s3-restore -t /var/s3-backup -b $BUCKET_NAME -r $REMOTE_PATH

# check the restore worked
output=$(sudo docker run --rm --name s3-backup-test-reader --volumes-from s3-backup-test-data-restore busybox sh -c 'cat /var/s3-backup/test')

if [[ "$output" != "test data" ]]
then
  echo "${RED}TEST FAILED"
  echo "Output was $output"
  exit 1
fi

cleanup

echo "${GREEN}PASSED"
