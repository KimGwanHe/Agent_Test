#!/bin/bash
# ============================================================
# NanoBot 모델 벤치마크 스크립트
# 사용법: ./benchmark.sh [모델명]
# 예시:   ./benchmark.sh qwen3:8b-16k
#         ./benchmark.sh qwen3:30b
#         ./benchmark.sh gemma3:12b
# ============================================================

set -e

MODEL=${1:-"qwen3:30b"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/benchmark_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULT_FILE="$RESULTS_DIR/${TIMESTAMP}_${MODEL//[:\/]/_}.md"

mkdir -p "$RESULTS_DIR"

# ── 색상 ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
head() { echo -e "${CYAN}$1${NC}"; }

# ── config.json 모델 변경 ─────────────────────────────────
switch_model() {
    local model=$1
    info "모델 변경 중: openai/${model}"
    # config.json의 model 값 교체
    sed -i "s|\"model\": \"openai/.*\"|\"model\": \"openai/${model}\"|g" config/config.json
    log "모델 변경 완료: openai/${model}"
    sleep 2  # 모델 로드 대기
}

# ── VRAM 사용량 측정 ──────────────────────────────────────
get_vram() {
    nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | tr -d ' '
}

get_vram_free() {
    nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null | tr -d ' '
}

# ── 메모리 저장 여부 확인 ─────────────────────────────────
check_memory_saved() {
    local before=$1
    local after=$(cat workspace/memory/MEMORY.md 2>/dev/null | wc -c)
    if [ "$after" -gt "$before" ]; then
        echo "✅ 저장됨"
    else
        echo "❌ 저장 안됨"
    fi
}

# ── 로그에서 Tool use 확인 ────────────────────────────────
check_tool_use() {
    local log_file=$1
    if grep -q "Tool call:" "$log_file" 2>/dev/null; then
        local tools=$(grep "Tool call:" "$log_file" | awk -F'Tool call: ' '{print $2}' | awk -F'(' '{print $1}' | tr '\n' ', ' | sed 's/,$//')
        echo "✅ 성공 ($tools)"
    else
        echo "❌ 미사용"
    fi
}

# ── 단일 테스트 실행 ──────────────────────────────────────
run_test() {
    local test_name=$1
    local message=$2
    local log_file="/tmp/nanobot_test_$$.log"

    info "테스트: $test_name"

    # VRAM 측정 (before)
    local vram_before=$(get_vram)
    local mem_before=$(cat workspace/memory/MEMORY.md 2>/dev/null | wc -c)

    # 첫 토큰 시간(TTFT) & 전체 응답 시간 측정
    local start_time=$(date +%s%3N)
    local first_token_time=""

    # 실행 (로그 캡처)
    docker compose --profile cli run --rm nanobot-cli agent --logs -m "$message" \
        2>"$log_file" | while IFS= read -r line; do
            if [ -z "$first_token_time" ] && echo "$line" | grep -q "🐈\|Response"; then
                first_token_time=$(date +%s%3N)
                echo "TTFT:$((first_token_time - start_time))" >> "/tmp/ttft_$$.txt"
            fi
            echo "$line"
        done

    local end_time=$(date +%s%3N)
    local total_time=$((end_time - start_time))
    local ttft=$(cat "/tmp/ttft_$$.txt" 2>/dev/null | grep TTFT | awk -F':' '{print $2}' || echo "N/A")

    # VRAM 측정 (after)
    local vram_after=$(get_vram)
    local vram_diff=$((vram_after - vram_before))

    # Tool use & 메모리 저장 확인
    local tool_result=$(check_tool_use "$log_file")
    local memory_result=$(check_memory_saved "$mem_before")

    # 결과 출력
    echo ""
    echo "  ┌─────────────────────────────────────┐"
    echo "  │ 테스트: $test_name"
    echo "  │ 응답 시간:    ${total_time}ms"
    echo "  │ TTFT:         ${ttft}ms"
    echo "  │ VRAM before:  ${vram_before}MiB"
    echo "  │ VRAM after:   ${vram_after}MiB"
    echo "  │ VRAM 증가:    +${vram_diff}MiB"
    echo "  │ Tool use:     $tool_result"
    echo "  │ 메모리 저장:  $memory_result"
    echo "  └─────────────────────────────────────┘"

    # 파일에 저장
    cat >> "$RESULT_FILE" << EOF

### $test_name
| 항목 | 결과 |
|---|---|
| 응답 시간 | ${total_time}ms |
| TTFT | ${ttft}ms |
| VRAM (before→after) | ${vram_before}→${vram_after}MiB (+${vram_diff}MiB) |
| Tool use | $tool_result |
| 메모리 저장 | $memory_result |

EOF

    rm -f "$log_file" "/tmp/ttft_$$.txt"
    sleep 3  # 다음 테스트 전 대기
}

# ── 메인 ──────────────────────────────────────────────────
echo ""
head "================================================"
head "  🐈 NanoBot 벤치마크"
head "  모델: $MODEL"
head "  시작: $(date)"
head "================================================"
echo ""

# 모델 변경
switch_model "$MODEL"

# MEMORY.md 초기화 (깨끗한 테스트를 위해)
warn "MEMORY.md 초기화 중..."
cat > workspace/memory/MEMORY.md << 'EOF'
# Long-term Memory

This file stores important information that should persist across sessions.

## User Information
## Preferences
## Project Context
## Important Notes

---
*This file is automatically updated by nanobot when important information should be remembered.*
EOF

# 결과 파일 헤더 작성
cat > "$RESULT_FILE" << EOF
# 🐈 NanoBot 벤치마크 결과

- **모델**: openai/$MODEL
- **날짜**: $(date)
- **GPU**: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "N/A")
- **VRAM 총량**: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null || echo "N/A")MiB

---

## 테스트 결과

EOF

# ── 테스트 1: 단순 응답 ────────────────────────────────────
run_test "단순 응답" "안녕하세요! 오늘 날씨 어때요?"

# ── 테스트 2: Tool use (메모리 저장) ──────────────────────
run_test "메모리 저장 (Tool use)" "내 이름은 홍길동이고 Python 백엔드 개발자야. 기억해줘"

# ── 테스트 3: 저장된 메모리 회상 ──────────────────────────
run_test "메모리 회상" "내 이름이 뭐야? 직업은?"

# ── 테스트 4: 코딩 능력 ───────────────────────────────────
run_test "코딩 능력" "Python으로 피보나치 수열 10번째 항 구하는 함수 짜줘"

# ── 테스트 5: 복잡한 Tool use ─────────────────────────────
run_test "복잡한 Tool use" "지금 날짜와 시간을 확인하고 MEMORY.md에 '마지막 접속: [날짜]' 형식으로 저장해줘"

# ── 최종 요약 ──────────────────────────────────────────────
echo ""
head "================================================"
head "  📊 벤치마크 완료!"
head "  결과 파일: $RESULT_FILE"
head "================================================"
echo ""

# 결과 파일에 요약 추가
cat >> "$RESULT_FILE" << EOF

---

## 📋 총평

| 항목 | 평가 |
|---|---|
| Tool use 능력 | |
| 메모리 관리 | |
| 응답 품질 | |
| 속도 | |
| 종합 점수 | /10 |

> 비고: 

EOF

log "결과 저장 완료: $RESULT_FILE"
echo ""
warn "총평 항목을 직접 채워주세요: vim $RESULT_FILE"
