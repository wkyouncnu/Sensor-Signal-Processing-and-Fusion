# GNC 규약 (MSS toolbox 기준)

원본: https://github.com/cybergalactic/MSS — `demoOtterUSVHeadingControl_P_D_Waypoint.slx` 내부를
그대로 따른다. 아래는 실제로 틀렸다가 고친 것들이다.

## 1. 유도는 `ψ_ref` 를 출력한다

침로각 `χ` 가 아니다. 크랩각 보상은 유도 안에서 하고 밖으로는 선수각 지령만 낸다.

```
χ = ψ + β,     β = atan2(v, u)
```

## 2. 속도 되먹임은 `u` (surge) 만

`U = sqrt(u²+v²)` 를 쓰면 옆으로 밀릴 때 전진 속도를 과대평가한다.

## 3. 헤딩은 P–D, 오차를 미분하지 않는다

```
tau_N = Kp · ssa(psi_ref − psi) − Kd · r
```

- `r` 을 직접 되먹임한다. 오차 미분은 지령이 계단으로 바뀔 때 튄다
- `ssa()` — smallest signed angle. ±π 경계에서 반대로 도는 것을 막는다

## 4. 유도법칙 두 가지

```matlab
% 목표를 향해 간다 (경로를 벗어나도 모른다)
psi_ref = atan2(yk1 - pe, xk1 - pn);

% 경로를 따라간다 (LOS)
y_e     = -(pn - xk)*sin(pi_p) + (pe - yk)*cos(pi_p);
psi_ref = pi_p - atan(y_e / Delta);
```

- `Delta` 작으면 공격적, 크면 완만
- 웨이포인트 전환은 **수락반경 `R`**

## 5. 벡터필드 로이터링

```matlab
N       = sqrt((r - rd)^2 + (pc*r)^2);
r_dot   = -vd * (r - rd) / N;
rth_dot =  vd * pc * r   / N;
chi_d   = atan2(vfE, vfN);        % 식 (13)
```

- **`p_c > 0` 이 시계방향** (참고 코드의 한글 주석이 반대로 적혀 있던 사례가 있음)
- 설계식: `p_c = 4ζ_c² · v · τ_r / r_d`
- 반경 정상상태 오차: `r_ss − r_d = p_c · v · τ_eff` — `p_c` 에 **정확히 비례**한다

## 6. 차동 추진 배분 (후방 2추진기)

```
X = FL + FR
N = (FL − FR) · b        % b = half beam
```

- 역변환: `FL = X/2 + N/(2b)`, `FR = X/2 − N/(2b)`
- **포화를 먼저 의심하라.** 추종 오차가 이상하면 `F_max` 부터 확인한다
  (1.5 m/s 정속에 한쪽 244 N 이 필요한데 `F_max = 250` 이면 선회 여유가 없다)

## 7. 프로펠러·모터 모델

- Gazebo 추진기 플러그인은 **뉴턴을 직접** 받는다 (PWM 아님)
- 그래도 모델에 넣는 이유는 **응답 지연**을 재현하기 위함
  - `k = ρ·Ct·D⁴`, `F = k·n·|n|`, 1차 지연 `τ_motor`
