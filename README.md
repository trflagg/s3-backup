# s3-backup

A pair of [Docker](https://www.docker.io/) containers which backup up a local path to S3 and later restores the backups.

The containers are designed to be used with the volumes-from option to backup the contents of a data only container. It adds the file(s) to backup to a tarfile
and then uploads them to the specified S3 bucket. Restoring does the same in reverse.

## Usage

Backing up:
```
docker run --rm --volumes-from my-data-only-container digit/s3-backup -s /path/in/container -b bucket-name -r path/on/bucket
```

Restoring:
```
docker run --rm --volumes-from my-data-only-container digit/s3-restore -b bucket-name -r path/on/bucket
```

## Example usage

Suppose you have a data container created by running something like this:

```
docker run -v /var/volume1 -name foo-data busybox true
```

Then normally you would start the container which runs your program/service and make it use the data containers volume:

```
docker run -d --volumes-from foo-data -name foo my-registry/foo
```

You do this because then you can kill the foo container and have the data in /var/volume1 persisted in the data only foo-data container.

Now when you want to backup the data in your data only container you can use this container to do so.

Let's say you have a bucket foo-backup and you want to backup the contents of /var/volume1 to the foo-backups directory there. The following command should do it:

```
docker run --rm --volumes-from foo-data digit/s3-backup -s /var/volume1 -b foo-backup -r foo-backup/my-backup.tar.gz
```

Later on if you want to restore a backup it's as simple as:

```
docker run --rm --volumes-from foo-data digit/s3-restore -b foo-backup -r foo-backup/my-backup.tar.gz
```
