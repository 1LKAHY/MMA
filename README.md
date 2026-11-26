# MMA 2025–2026
1. Supabase SQL Editor에서 supabase/setup.sql의 CHANGE_THIS_PASSWORD를 긴 고유 비밀번호(72바이트 이하)로 바꿔 실행. 결과의 private_vote_link를 복사해 단톡방에만 공유. SQL 재실행 시 링크가 바뀜. 기존 투표는 새 테이블에 이관되지 않음.
2. ZIP을 풀고 내부 파일 및 숨김 폴더 .github를 GitHub MMA 저장소 main에 업로드. SQL 파일에 실제 비밀번호를 넣어 업로드하지 말 것.
3. Settings > Secrets and variables > Actions에 SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY 등록. service_role/secret 금지.
4. Settings > Pages > Source: GitHub Actions. Actions에서 Deploy MMA to Pages 실행 확인.
5. 공유 링크로 투표 테스트, 기본 주소에서 관리자 비밀번호로 집계 확인. 테스트 투표는 SQL Editor에서 직접 삭제 가능.
공개 키 및 사이트 소스는 공개됨. 토큰은 URL fragment에만 전달되고 서버는 해시 검증. 결과 테이블 RLS 및 직접 권한 차단. 토큰 유출 시 투표 가능. 10초 재제출 제한은 전체 API DDoS 방어가 아님. 관리자 비밀번호 무차별 요청 제한 및 서버 측 후보 목록 검증은 미구현. 상 이름은 투표 UI에서 숨기지만 공개 소스에서는 확인 가능. 병합은 관리자 브라우저에 저장. 실제 Supabase 연결 및 브라우저 검증 필요.

이번 버전은 8개 부문입니다. 기존 9개 부문 투표가 있다면 배포 전 백업 및 초기화 또는 별도 이관이 필요합니다.
