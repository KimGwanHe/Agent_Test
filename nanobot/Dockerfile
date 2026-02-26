FROM python:3.11-slim

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    git \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# nanobot-ai 최신 버전 설치
RUN pip install --no-cache-dir nanobot-ai

# 워크스페이스 디렉토리 생성
RUN mkdir -p /root/.nanobot/workspace /root/.nanobot/config

# 기본 포트 노출 (게이트웨이 WebSocket)
EXPOSE 18790

# 헬스체크
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:18790/health || exit 1

ENTRYPOINT ["nanobot"]
CMD ["--help"]
