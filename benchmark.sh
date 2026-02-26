#!/bin/bash
# ============================================================
# Agent_test 벤치마크 스크립트
# 사용법: ./benchmark.sh [framework] [test]
# 예시:   ./benchmark.sh nanobot memory
#         ./benchmark.sh all speed
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/benchmark_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$RESULTS_DIR"

# 색상 출력
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# ─── 메모리 사용량 측정 ──────────────────────────────────────
test_memory() {
    local framework=$1
    local container_name="${framework}-gateway"

    info "측정 중: ${framework} 메모리 사용량..."

    # 컨테이너가 실행 중인지 확인
    if ! docker ps --format '{{.Names}}' | grep -q "$container_name"; then
        warn "${container_name} 컨테이너가 실행 중이지 않습니다"
        return 1
    fi

    # 메모리 측정 (5회 평균)
    local total=0
    for i in {1..5}; do
        mem=$(docker stats "$container_name" --no-stream --format "{{.MemUsage}}" | awk '{print $1}')
        echo "  측정 $i: $mem"
        sleep 1
    done

    log "${framework} 메모리 측정 완료"
}

# ─── 응답 속도 측정 ──────────────────────────────────────────
test_speed() {
    local framework=$1
    local test_message="1+1은 얼마인가요? 숫자만 대답해주세요."

    info "${framework} 응답 속도 측정 중..."

    local start_time=$(date +%s%3N)

    case $framework in
        nanobot)
            cd "$SCRIPT_DIR/nanobot"
            docker compose run --rm nanobot-cli agent -m "$test_message" > /dev/null 2>&1
            ;;
        picoclaw)
            cd "$SCRIPT_DIR/picoclaw"
            docker compose run --rm picoclaw-cli agent -m "$test_message" > /dev/null 2>&1
            ;;
        goose)
            cd "$SCRIPT_DIR/goose"
            echo "$test_message" | docker compose run --rm goose > /dev/null 2>&1
            ;;
    esac

    local end_time=$(date +%s%3N)
    local elapsed=$((end_time - start_time))

    log "${framework} 응답 시간: ${elapsed}ms"
    echo "${TIMESTAMP},${framework},speed,${elapsed}ms" >> "$RESULTS_DIR/results.csv"
}

# ─── 코딩 능력 테스트 ────────────────────────────────────────
test_coding() {
    local framework=$1
    local test_prompt="Python으로 피보나치 수열의 첫 10개 항을 출력하는 코드를 작성하고 실행해줘"

    info "${framework} 코딩 테스트 중..."

    case $framework in
        nanobot)
            cd "$SCRIPT_DIR/nanobot"
            docker compose run --rm nanobot-cli agent -m "$test_prompt" \
                2>&1 | tee "$RESULTS_DIR/${TIMESTAMP}_${framework}_coding.txt"
            ;;
        *)
            warn "${framework} 코딩 테스트 미구현"
            ;;
    esac
}

# ─── 메모리(기억) 기능 테스트 ────────────────────────────────
test_memory_feature() {
    local framework=$1

    info "${framework} 메모리(기억) 기능 테스트 중..."

    case $framework in
        nanobot)
            cd "$SCRIPT_DIR/nanobot"
            # 정보 저장
            docker compose run --rm nanobot-cli agent -m \
                "나는 Agent_test 프로젝트를 진행하는 개발자야. 이것을 기억해줘" 2>&1
            sleep 2
            # 기억 확인
            docker compose run --rm nanobot-cli agent -m \
                "내가 어떤 프로젝트를 진행하고 있다고 했지?" 2>&1
            ;;
    esac
}

# ─── 전체 요약 보고서 ────────────────────────────────────────
generate_report() {
    local report_file="$RESULTS_DIR/${TIMESTAMP}_report.md"

    cat > "$report_file" << EOF
# 벤치마크 결과 보고서
**실행 시간**: $(date)

## 메모리 사용량
| 프레임워크 | 측정값 |
|---|---|
| NanoBot | - |
| PicoClaw | - |
| Goose | - |

## 응답 속도
$(cat "$RESULTS_DIR/results.csv" 2>/dev/null || echo "데이터 없음")

## 결론
- 가장 빠른 응답: -
- 가장 적은 메모리: -
- 코딩 능력 최고: -
EOF

    log "보고서 생성: $report_file"
}

# ─── 메인 ────────────────────────────────────────────────────
FRAMEWORK=${1:-"nanobot"}
TEST=${2:-"speed"}

echo ""
echo "================================================"
echo "  Agent_test 벤치마크"
echo "  프레임워크: $FRAMEWORK | 테스트: $TEST"
echo "================================================"
echo ""

case $TEST in
    memory)
        test_memory "$FRAMEWORK"
        ;;
    speed)
        test_speed "$FRAMEWORK"
        ;;
    coding)
        test_coding "$FRAMEWORK"
        ;;
    memory-feature)
        test_memory_feature "$FRAMEWORK"
        ;;
    all)
        if [ "$FRAMEWORK" == "all" ]; then
            for fw in nanobot picoclaw goose; do
                test_speed "$fw"
                test_memory "$fw"
            done
        else
            test_speed "$FRAMEWORK"
            test_memory "$FRAMEWORK"
            test_coding "$FRAMEWORK"
        fi
        generate_report
        ;;
    *)
        echo "사용법: $0 [nanobot|picoclaw|goose|openclaw|all] [speed|memory|coding|memory-feature|all]"
        ;;
esac
