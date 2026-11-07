#!/bin/sh
# 全新实例，与 Compose 二选一。不会覆盖已存在的同名容器。
set -eu
SHIYU_IMAGE=${SHIYU_IMAGE:-xuelingyun/shiyu:dev}
SHIYU_BIND_IP=${SHIYU_BIND_IP:-127.0.0.1}
SHIYU_HTTP_PORT=${SHIYU_HTTP_PORT:-18930}
SHIYU_MEMORY_MB=${SHIYU_MEMORY_MB:-768}
SHIYU_CPUS=${SHIYU_CPUS:-2.0}
SHIYU_DATA_DIR=${SHIYU_DATA_DIR:-"$(pwd)/data"}
case "$SHIYU_DATA_DIR" in /*) ;; *) echo 'SHIYU_DATA_DIR 必须为绝对路径' >&2; exit 1 ;; esac
mkdir -p "$SHIYU_DATA_DIR"
docker run -d --name shiyu-core \
  --restart unless-stopped --network host \
  --read-only --cap-drop ALL \
  --cap-add CHOWN --cap-add FOWNER --cap-add DAC_OVERRIDE \
  --cap-add SETUID --cap-add SETGID --cap-add KILL \
  --security-opt no-new-privileges:true \
  --memory "${SHIYU_MEMORY_MB}m" --memory-reservation 256m \
  --memory-swap "${SHIYU_MEMORY_MB}m" --cpus "$SHIYU_CPUS" \
  --pids-limit 128 --oom-score-adj 500 --stop-timeout 70 \
  --tmpfs /run:rw,noexec,nosuid,size=32m,mode=0755 \
  --tmpfs /tmp:rw,noexec,nosuid,size=32m,mode=1777 \
  --mount "type=bind,source=$SHIYU_DATA_DIR,target=/data" \
  --env "SHIYU_LISTEN=$SHIYU_BIND_IP:$SHIYU_HTTP_PORT" \
  --env "SHIYU_MEMORY_MB=$SHIYU_MEMORY_MB" --env "TZ=${TZ:-Asia/Shanghai}" \
  --log-driver json-file --log-opt max-size=5m --log-opt max-file=2 \
  "$SHIYU_IMAGE"
