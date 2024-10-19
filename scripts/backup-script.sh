#!/bin/bash

# Variables
#DB_URI="mongodb://username:password@host:port/dbname"
BUCKET_NAME="1019mdbbackups"
DATE=$(date +%F)
BACKUP_DIR="/tmp/mongobackups"
ARCHIVE_NAME="mongodump-$DATE.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Log start time
echo "Starting backup at $(date)" >> /root/backup.log

# Create MongoDB dump and compress it
mongodump  --archive=$ARCHIVE_PATH --gzip

# Check if mongodump succeeded
if [ $? -eq 0 ]; then
    echo "Backup succeeded, uploading to S3" >> /root/scripts/backup.log
    # Upload the compressed dump to S3
    aws s3 cp $ARCHIVE_PATH s3://$BUCKET_NAME/backups/$ARCHIVE_NAME
else
    echo "Backup failed!" >> /root/scripts/backup.log
    exit 1
fi

# Log upload status
if [ $? -eq 0 ]; then
    echo "Upload succeeded at $(date)" >> /root/scripts/backup.log
else
    echo "Upload failed!" >> /root/scripts/backup.log
    exit 1
fi

# Optional: Remove local backups older than 7 days
find $BACKUP_DIR -type f -mtime +7 -name '*.gz' -exec rm {} \;

# Log end time
echo "Backup and cleanup completed at $(date)" >> /root/scripts/backup.log

