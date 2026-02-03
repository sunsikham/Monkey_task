function acc_map = update_accuracy(acc_map, n_rects, is_correct)
% UPDATE_ACCURACY  n_rects 조합별·전체 누적 정확도 갱신 및 저장
%
%   acc_map = UPDATE_ACCURACY(acc_map, n_rects, is_correct, ledger_file)
%
%   입력
%   ----
%   acc_map     : 누적 정보(struct). 첫 호출 시 [] 또는 존재하면 그대로.
%   n_rects     : 1×k 벡터, 이번 트라이얼에서 사용한 사각형 개수 조합
%   is_correct  : 논리값, 정답이면 true
%   ledger_file : 누적 정보를 저장할 .mat 파일 경로
%
%   출력
%   ----
%   acc_map     : 갱신된 누적 정보(struct)


    % ───────────────── 1) 키(조합) 생성 ────────────────────────────
   key = sprintf('%d_', sort(n_rects));   % '2_3_' 형태
    key(end) = [];                         % 뒤쪽 '_' 삭제

    % ② 첫 글자가 문자여야 하므로 접두사 추가 (ex: 'n_2_3')
    key = ['n_' key];
    
    % ───────────────── 2) 신규 조합 초기화 ────────────────────────
    if ~isfield(acc_map, key)
        acc_map.(key).total   = 0;
        acc_map.(key).correct = 0;
    end

    % ───────────────── 3) 카운트 갱신 ──────────────────────────────
    acc_map.(key).total   = acc_map.(key).total   + 1;
    acc_map.(key).correct = acc_map.(key).correct + is_correct;

    % ───────────────── 4) 출력 ────────────────────────────────────
    combos = fieldnames(acc_map);
    grand_total = 0;     % 전체 시도
    grand_hits  = 0;     % 전체 정답

    fprintf('\n===== n_rects 조합별 누적 정확도 =====\n');
    for i = 1:numel(combos)
        combo = combos{i};
        hits  = acc_map.(combo).correct;
        N     = acc_map.(combo).total;
        grand_hits  = grand_hits  + hits;
        grand_total = grand_total + N;

        fprintf('[%s]  %3d / %3d  (%.2f%%)\n', ...
                strrep(combo,'_',' & '), hits, N, 100*hits/N);
    end
    fprintf('---------------------------------------------\n');
    fprintf('전체 정확도      %4d / %4d  (%.2f%%)\n', ...
            grand_hits, grand_total, 100*grand_hits/grand_total);
    fprintf('=============================================\n\n');
end