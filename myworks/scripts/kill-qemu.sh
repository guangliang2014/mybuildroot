#!/bin/sh
# kill-qemu.sh — 优雅终止 qemu，超时后强制杀死

set -eu

# 匹配正在运行的 qemu-system 进程
PIDS=$(pgrep -f "qemu-system" || true)

if [ -z "$PIDS" ]; then
  echo "No qemu-system processes found."
  exit 0
fi

echo "Found QEMU PIDs: $PIDS"
# 先发送 TERM 请求优雅退出
echo "$PIDS" | xargs -r kill -TERM

# 等待若干秒让它们自行退出
WAIT=5
echo "Waiting ${WAIT}s for QEMU to exit..."
sleep $WAIT

# 检查是否仍有进程存活
SURVIVORS=$(pgrep -f "qemu-system" || true)
if [ -n "$SURVIVORS" ]; then
  echo "Processes still running: $SURVIVORS"
  echo "Sending SIGKILL..."
  echo "$SURVIVORS" | xargs -r kill -KILL
else
  echo "QEMU exited cleanly."
fi

