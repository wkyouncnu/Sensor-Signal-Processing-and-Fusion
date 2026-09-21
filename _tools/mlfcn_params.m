function mlfcn_params(blk, names)
%MLFCN_PARAMS  MATLAB Function 블록의 입력 가운데 일부를 "파라미터"로 바꾼다.
%              Turn some inputs of a MATLAB Function block into parameters.
%
%   mlfcn_params(blk, {'k_pos','k_neg'})
%
%   왜 / why
%       함수 인자로 적은 이름은 기본적으로 입력 포트가 된다. 상수(추력 계수, 팔 길이)를
%       포트로 두면 캔버스에 Constant 블록이 줄줄이 붙어 읽기 어렵다. 파라미터로 바꾸면
%       포트가 사라지고 값은 같은 이름의 작업공간 변수에서 온다 (W03_0_setup 등).
%       Every argument of the function is an input port by default. Constants
%       as ports hang a row of Constant blocks on the canvas. As parameters the
%       ports disappear and the values come from the workspace variables of the
%       same names (W03_0_setup and so on).
%
%   set_mlfcn 으로 코드를 넣은 뒤에 부른다 / call after set_mlfcn has set the code.

c = sfroot().find('-isa','Stateflow.EMChart','-and','Path',blk);
if isempty(c), error('mlfcn_params:notFound', 'No MATLAB Function block at %s', blk); end
for i = 1:numel(names)
    d = c.find('-isa','Stateflow.Data','-and','Name',names{i});
    if isempty(d), error('mlfcn_params:noData', '%s is not an argument of %s', names{i}, blk); end
    d.Scope = 'Parameter';
end
end
