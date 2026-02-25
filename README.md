피코클로 → PicoClaw (Go 기반, 초경량)
나노봇 → NanoBot (Python 기반, 초경량)
구스 → Goose (block/goose, Rust 기반)
오픈클로 → OpenClaw (TypeScript 기반, 엔터프라이즈급)


1. 🦞 OpenClaw (openclaw/openclaw, TypeScript)
출시: 원조 개인 AI 어시스턴트. Node.js + TypeScript 기반
규모: 430,000줄+ 코드, ~1.5GB RAM
채널: WhatsApp, Telegram, Slack, Discord, Signal, iMessage, MS Teams 등 13개+
특징: ClawHub 스킬 레지스트리(5,700+ 커뮤니티 스킬), 서브에이전트, 음성, Canvas
LLM: Claude, GPT, Gemini, Ollama 등 모두 지원
Docker 지원: ✅ 공식 지원
GitHub: github.com/openclaw/openclaw

2. 🐈 nanobot (HKUDS/nanobot, Python)
출시: 2026년 2월 2일 (HKU 데이터 지능 연구실)
규모: ~4,000줄 코드, ~100MB RAM (OpenClaw 대비 99% 감소)
현재 버전: v0.1.4.post2 (2026-02-24 최신)
채널: Telegram, Discord, Slack, Email, QQ, WhatsApp, Feishu 등
LLM: OpenAI, Anthropic, Gemini, DeepSeek, Qwen, Ollama, vLLM, OpenRouter 등 11개+ 프로바이더
특징: MCP 지원, HEARTBEAT.md 주기적 태스크, 메모리 시스템(MEMORY.md), 서브에이전트
Docker 지원: ✅ 공식 docker-compose 지원
GitHub: github.com/HKUDS/nanobot

3. 🦐 PicoClaw (sipeed/picoclaw, Go)
출시: 2026년 2월 9일 (단 하루 만에 개발!)
규모: <10MB RAM, 1초 미만 부팅
특징: 코드의 95%가 AI 에이전트가 자동 생성. RISC-V/ARM/x86 단일 바이너리
채널: Telegram, Discord, QQ, DingTalk, LINE, Slack, WeCom
LLM: OpenRouter, Anthropic, OpenAI, Gemini, Ollama(로컬), Groq 등
주의: v1.0 미만, 프로덕션 비권장. 보안 이슈 가능성 있음
Docker 지원: ✅ docker-compose 지원
GitHub: github.com/sipeed/picoclaw

4. 🪿 Goose (block/goose, Rust)
출시: 2025년 1월 Block(구 Square)사 공개
특징: 코딩 에이전트 특화. 설치/실행/수정/테스트 자율 수행
규모: ~7.8MB, 30,000+ GitHub 스타, 350+ 기여자
LLM: 25개+ 프로바이더 (Anthropic, OpenAI, Gemini, Ollama 등)
확장: MCP 서버 3,000개+ 생태계
Docker 지원: ✅ 컨테이너 익스텐션 지원
GitHub: github.com/block/goose

