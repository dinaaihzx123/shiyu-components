#!/bin/sh
# 全新实例，与 Compose 二选一。不会覆盖已存在的同名容器。
set -eu
SHIYU_IMAGE=${SHIYU_IMAGE:-xuelingyun/shiyu:dev}
SHIYU_BIND_IP=${SHIYU_BIND_IP:-127.0.0.1}
SHIYU_HTTP_PORT=${SHIYU_HTTP_PORT:-18930}
SHIYU_MEMORY_MB=${SHIYU_MEMORY_MB:-768}
SHIYU_CPUS=${SHIYU_CPUS:-2.0}
SHIYU_STORAGE=${SHIYU_STORAGE:-bind}
SHIYU_PULL_POLICY=${SHIYU_PULL_POLICY:-missing}
case "$SHIYU_PULL_POLICY" in missing|never) ;; *) echo '拉取策略仅支持 missing 或 never' >&2; exit 1 ;; esac
case "$SHIYU_STORAGE" in
  bind)
    SHIYU_DATA_DIR=${SHIYU_DATA_DIR:-"$(pwd)/data"}
    case "$SHIYU_DATA_DIR" in /*) ;; *) echo 'SHIYU_DATA_DIR 必须为绝对路径' >&2; exit 1 ;; esac
    mkdir -p "$SHIYU_DATA_DIR"
    data_mount="type=bind,source=$SHIYU_DATA_DIR,target=/data"
    ;;
  volume)
    SHIYU_VOLUME_NAME=${SHIYU_VOLUME_NAME:-shiyu-data}
    case "$SHIYU_VOLUME_NAME" in ''|*[!A-Za-z0-9_.-]*) echo '数据卷名称无效' >&2; exit 1 ;; esac
    data_mount="type=volume,source=$SHIYU_VOLUME_NAME,target=/data"
    ;;
  *) echo '存储模式仅支持 bind 或 volume' >&2; exit 1 ;;
esac
docker run -d --name shiyu-core --pull "$SHIYU_PULL_POLICY" \
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
  --mount "$data_mount" \
  --env "SHIYU_LISTEN=$SHIYU_BIND_IP:$SHIYU_HTTP_PORT" \
  --env "SHIYU_MEMORY_MB=$SHIYU_MEMORY_MB" --env "TZ=${TZ:-Asia/Shanghai}" \
  --log-driver json-file --log-opt max-size=5m --log-opt max-file=2 \
  "$SHIYU_IMAGE"
