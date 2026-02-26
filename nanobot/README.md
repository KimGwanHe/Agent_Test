# 🐈 NanoBot 테스트 가이드

> HKU 데이터 지능 연구실의 초경량 Python AI 어시스턴트  
> OpenClaw 대비 99% 더 가볍고 (~100MB RAM), ~4,000줄의 깔끔한 Python 코드

## 📋 빠른 시작 체크리스트

- [ ] 1단계: .env 파일에 API 키 입력
- [ ] 2단계: Docker 이미지 빌드
- [ ] 3단계: 초기 설정 (onboard)
- [ ] 4단계: 첫 번째 대화 테스트
- [ ] 5단계: LLM 모델 교체 테스트
- [ ] 6단계: 채널 연동 (Telegram/Discord)
- [ ] 7단계: 커스텀 스킬 작성

---

## 🚀 1단계: 환경 설정

```bash
# Agent_test 루트에서 .env 설정
cd ~/Agent_test
cp .env.example .env
vim .env
# ANTHROPIC_API_KEY, OPENAI_API_KEY 등 입력
```

## 🔨 2단계: Docker 이미지 빌드

```bash
cd ~/Agent_test/nanobot

# 이미지 빌드
docker compose build

# 또는 캐시 없이 최신 버전으로
docker compose build --no-cache
```

## ⚙️ 3단계: 초기 설정 (onboard)

```bash
# config.json이 이미 준비되어 있으므로 바로 시작 가능
# 수동으로 onboard 진행하고 싶다면:
docker compose run --rm nanobot-cli onboard
```

## 💬 4단계: 첫 번째 대화 테스트

```bash
# 단발성 메시지 테스트
docker compose run --rm nanobot-cli agent -m "안녕하세요! 당신은 누구인가요?"

# 인터랙티브 모드 (대화형)
docker compose run --rm nanobot-cli agent

# 현재 상태 확인
docker compose run --rm nanobot-cli status
```

## 🤖 5단계: LLM 모델 교체 테스트

`config/config.json`의 `model` 값을 변경하여 테스트:

```json
{
  "agents": {
    "defaults": {
      "model": "anthropic/claude-sonnet-4-6"    // Anthropic Claude
      // "model": "openai/gpt-4o"               // OpenAI GPT-4o
      // "model": "google/gemini-2.0-flash"     // Google Gemini
      // "model": "ollama/llama3.2"             // Ollama 로컬 (무료)
      // "model": "ollama/qwen2.5:7b"           // Qwen 로컬 (무료)
    }
  }
}
```

### Ollama 로컬 LLM 연동

```bash
# Ollama 서버 실행
docker compose --profile ollama up -d ollama

# 모델 다운로드 (처음 한 번만)
docker exec nanobot-ollama ollama pull llama3.2
docker exec nanobot-ollama ollama pull qwen2.5:7b

# config.json에서 모델 변경 후 테스트
# "model": "ollama/llama3.2"
# OLLAMA_BASE_URL=http://ollama:11434  (.env에서 설정)
docker compose run --rm nanobot-cli agent -m "로컬 Ollama 테스트"
```

## 📡 6단계: Gateway 실행 (상시 실행)

```bash
# 백그라운드 게이트웨이 시작
docker compose --profile gateway up -d nanobot-gateway

# 로그 확인
docker compose logs -f nanobot-gateway

# 상태 확인
curl http://localhost:18790/health

# 게이트웨이 중지
docker compose --profile gateway down
```

## 🎯 7단계: 커스텀 스킬 작성

`skills/` 폴더에 SKILL.md 파일을 만들어 에이전트에게 새 능력을 부여할 수 있습니다.

```bash
mkdir -p skills/my-skill
cat > skills/my-skill/SKILL.md << 'EOF'
# My Custom Skill

## 설명
이 스킬은 ... 을 수행합니다.

## 사용법
에이전트에게 "..." 라고 말하면 이 스킬이 동작합니다.
EOF
```

---

## 📊 벤치마크 테스트 명령어

```bash
# 응답 시간 측정
time docker compose run --rm nanobot-cli agent -m "1+1은?"

# 메모리 사용량 확인 (게이트웨이 실행 중)
docker stats nanobot-gateway --no-stream

# 코딩 능력 테스트
docker compose run --rm nanobot-cli agent -m \
  "Python으로 피보나치 수열 10번째 항을 계산하는 코드를 작성하고 실행해줘"

# 메모리 기능 테스트
docker compose run --rm nanobot-cli agent -m "내 이름은 테스터야. 기억해줘"
docker compose run --rm nanobot-cli agent -m "내 이름이 뭐야?"

# 웹 검색 테스트 (Brave API 키 있을 때)
docker compose run --rm nanobot-cli agent -m "오늘 날씨 어때?"
```

## 🔍 Context 길이 변경 테스트

```json
{
  "agents": {
    "defaults": {
      "max_tokens": 4096,     // 짧은 응답
      // "max_tokens": 16384, // 긴 응답 허용
      "max_tool_iterations": 10,   // 도구 사용 제한
      // "max_tool_iterations": 30 // 복잡한 작업 허용
    }
  }
}
```

## ❗ 트러블슈팅

| 문제 | 해결책 |
|---|---|
| `config.json` 에러 | `.env` 파일에 해당 API 키가 있는지 확인 |
| Ollama 연결 실패 | `OLLAMA_BASE_URL`이 `http://ollama:11434`인지 확인 |
| 게이트웨이 헬스체크 실패 | `docker logs nanobot-gateway`로 오류 확인 |
| 메모리 초기화 | `./workspace/MEMORY.md` 삭제 후 재시작 |

## 📚 참고 링크

- [NanoBot GitHub](https://github.com/HKUDS/nanobot)
- [NanoBot 공식 문서](https://nanobot.club)
- [LLM 프로바이더 목록](https://github.com/HKUDS/nanobot#providers)
- [스킬 작성 가이드](https://github.com/HKUDS/nanobot#skills)



# Qwen3 8B (한국어 강함, 추천 1순위)
ollama pull qwen3:8b

# Gemma3 4B (구글, 빠르고 가벼움)
ollama pull gemma3:4b

# Mistral 7B (미니스트럴, 안정적)
ollama pull mistral

# Nemotron Mini 4B (레모트론, NVIDIA 최적화)
ollama pull nemotron-mini


┌─────────────────────────────────────────────┐
│              Ubuntu 서버                     │
│                                             │
│  ┌─────────────────────┐                   │
│  │  Docker 컨테이너     │                   │
│  │  (nanobot-cli)      │  ──요청──▶  Ollama │
│  │                     │  ◀──응답──  (로컬) │
│  │  nanobot 에이전트    │  172.18.0.1:11434  │
│  └─────────────────────┘                   │
│                                             │
│  nanobot = 에이전트 (대화, 도구 사용)         │
│  Ollama  = LLM 서버 (실제 AI 두뇌)           │
└─────────────────────────────────────────────┘


workspace/
├── AGENTS.md      ← 에이전트 역할/페르소나 정의
│                    "너는 개발 도우미야, 항상 한국어로 답해" 같은 설정
├── USER.md        ← 사용자 정보 저장
│                    이름, 선호도, 습관 등 에이전트가 나를 기억하는 곳
├── SOUL.md        ← 에이전트 성격/가치관 정의
│                    말투, 태도, 응답 스타일 설정
├── TOOLS.md       ← 사용 가능한 도구 목록/설정
│                    웹 검색, 파일 읽기, 코드 실행 등
├── HEARTBEAT.md   ← 주기적 자동 실행 태스크 정의
│                    "매일 아침 날씨 체크해줘" 같은 스케줄
└── memory/
    ├── MEMORY.md  ← 대화 내용 중 중요한 것 장기 저장
    │                "사용자가 Python 개발자라고 했음" 등
    └── HISTORY.md ← 전체 대화 히스토리 로그