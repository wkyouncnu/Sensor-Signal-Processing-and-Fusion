function run_alone(tag, mdl)
%RUN_ALONE  Run 만 눌러도 돌고, 실시간 화면까지 뜨게 한다 — 매 Run 마다 불린다
%
%   run_alone('W06')            bdroot 에 대고 / against bdroot
%   run_alone('W06', bdroot)    모델을 명시해서 / with the model named
%
%  무엇을 푸는가 / the problem this solves
%      이 볼트의 모델은 Constant 에 **숫자가 아니라 이름**을 담는다 (h · T_final ·
%      x0 · Kp_pos · …). 그래서 학생이 `.slx` 를 더블클릭해 열고 Run 을 누르면,
%      작업공간이 비어 있는 새 세션에서는 첫 변수에서 멈춘다 —
%
%          Error: Undefined function or variable 'h'
%
%      그리고 그 메시지는 **모델이 깨진 것처럼** 읽힌다. 깨진 것이 아니다.
%      WXX_0_setup 을 먼저 돌리면 되지만, 학생은 그것을 모른다. 그래서 모델이
%      **스스로** 챙긴다. 사용자 지시: "시뮬링크만 돌려도 애니메이션 나오도록".
%
%      Every Constant in this vault holds a NAME, not a number, so pressing Run
%      in a fresh session stops at the first one -- and the message reads as if
%      the model were corrupt. It is not. The model now fills the gap itself.
%
%  무엇을 하는가, 매 Run 마다 / what it does on every Run
%      1. MSS 를 경로에 얹는다. otter.m 이 없으면 플랜트가 돌지 않는다
%      2. **없는 변수만** 채운다 — WXX_vars 를 씨앗으로 ensure_base_vars 가 한다.
%         이미 있는 값은 건드리지 않으므로, 학생이 게인을 바꿔 놓고 Run 을
%         눌렀을 때 그 값이 되살아나 덮이지 않는다
%      3. 실시간 화면을 켠다 — 사람이 Run 을 눌렀을 때만 (아래)
%      4. pace 를 읽어 현실 시간 진행을 켜거나 끈다
%
%  왜 animate 를 1 로 올리는가 / why animate is forced on
%      WXX_vars 는 `animate = 0` 이다. 절 스크립트는 **조용히 빨리** 돌아야 하기
%      때문이다. 그러나 사람이 Run 을 눌렀다면 화면을 보고 싶은 것이다. 그래서
%      여기서는 1 로 올린다 — 단, 절 스크립트가 도는 중이면(`<tag>batch` 가 서
%      있으면) 올리지 않는다. 화면을 그리면 표 하나 뽑는 데 몇 분이 걸린다.
%
%      WXX_vars sets animate = 0 because a section script must run quietly and
%      fast. A person pressing Run wants the window, so it is raised to 1 here --
%      unless a section script is running, which `<tag>batch` tells us.
%
%  왜 Animate 블록을 빼지 않는가 / why the block is never removed
%      끄는 것은 **상수 하나**이지 블록이 아니다. animate = 0 이면 블록은
%      그대로 있고 아무것도 하지 않는다. 빼 버리면 도면이 주차마다 달라지고,
%      학생이 "내 모델에는 그 블록이 없다" 고 묻게 된다.
%
%  왜 주차마다 복사하지 않는가 / why this is one shared function
%      CLAUDE.md §15-34. 주차 넷이 같은 일을 하면 함수 하나로 두고 넷이 부른다.
%      복사해 두면 한쪽만 고쳐지고, 그 한쪽은 몇 달 뒤에 발견된다.
%
%  모델 쪽 배선 / how a model calls this
%      빌더가 InitFcn 에 두 문장을 적어 둔다. 경로를 **먼저** 얹어야 이 함수가
%      불릴 수 있으므로 addpath 는 콜백 안에 있어야 한다 —
%
%          addpath(fullfile(fileparts(fileparts(fileparts( ...
%                  get_param(bdroot,'FileName')))), '_tools'), ...
%                  fileparts(get_param(bdroot,'FileName')));
%          run_alone('W06', bdroot);
%
%      첫 문장이 `_tools` 와 그 주차 폴더를 얹고, 둘째가 나머지를 한다.
%
%  일괄 실행과 부딪히지 않는가 / does this fight a batch run?
%      않는다. WXX_read 는 Simulink.SimulationInput 으로 변수를 넘기고, 그것은
%      작업공간보다 **우선**한다. 그래서 여기서 animate 를 올려도 절 스크립트의
%      animate = 0 이 이긴다. 거기에 `<tag>batch` 검사가 한 겹 더 있다.
%
%   See also ENSURE_BASE_VARS, BASE_VAR, MSS_PATH, LIVE_DASH.

if nargin < 2 || isempty(mdl), mdl = bdroot; end

%% 1) MSS. 없으면 플랜트의 otter.m 이 해결되지 않는다
mss_path();

%% 2) 없는 변수만 채운다. 있는 것은 그대로 둔다
V = feval([tag '_vars']);
if ~evalin('base', sprintf('exist(''%sbatch'', ''var'')', tag))
    %  사람이 Run 을 눌렀다 — 실시간 화면을 켠다
    V.animate = 1;
end
ensure_base_vars(V);

%% 3) 현실 시간. 모델에 박아 두지 않고 매 Run 마다 읽는다
if base_var('pace', 0) > 0
    set_param(mdl, 'EnablePacing', 'on', 'PacingRate', '1');
else
    set_param(mdl, 'EnablePacing', 'off');
end
end
