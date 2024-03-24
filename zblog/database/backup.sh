#!/usr/bin/env bash
set -x

SCRIP_DIR="$( dirname "${BASH_SOURCE[0]}" )"

CONTAINER_NAME="wp-database"
VOLUME_NAME="wp_db-data"
LOC_VOLUME_PATH="./${VOLUME_NAME}"
VOLUME_PATH='/var/lib/mysql'
LOC_BACKUP_PATH="${SCRIP_DIR}/backup"
BACKUP_PATH='/backup'

 # make backup
# docker run --rm --volumes-from "${CONTAINER_NAME}" -v ${LOC_BACKUP_PATH}:${BACKUP_PATH} ubuntu tar cvf ${BACKUP_PATH}/backup.tar "${VOLUME_PATH}"
# docker run --rm  -v "${VOLUME_NAME}":"${VOLUME_PATH}" -v ${LOC_BACKUP_PATH}:${BACKUP_PATH} ubuntu tar cvf ${BACKUP_PATH}/backup.tar "${VOLUME_PATH}"

 # restore backup
# docker run --rm --volumes-from "${CONTAINER_NAME}" -v ${LOC_BACKUP_PATH}:${BACKUP_PATH} ubuntu bash -c "cd ${VOLUME_PATH} && tar xvf ${BACKUP_PATH}/backup.tar --strip 1"
docker run --rm -v ${VOLUME_NAME}:${VOLUME_PATH} -v ${LOC_BACKUP_PATH}:${BACKUP_PATH} ubuntu bash -c "cd ${VOLUME_PATH} && rm -vrf ./* && tar xvf ${BACKUP_PATH}/backup.tar --strip 1"
