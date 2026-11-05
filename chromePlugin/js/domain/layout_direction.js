/** 'vertical'은 위에서 아래로 쌓고, 'horizontal'은 왼쪽에서 오른쪽으로 붙인다. */
export const LayoutDirection = Object.freeze({
  vertical: Object.freeze({ code: 'vertical' }),
  horizontal: Object.freeze({ code: 'horizontal' }),
});

/**
 * 비율(가로÷세로)의 기하 평균이 1 이상이면 세로 배치, 1 미만이면 가로 배치 (DESIGN §2.1.2).
 * 기하 평균 ≥ 1 ⇔ Σ ln r ≥ 0. 부동소수점 오차로 1 바로 아래가 되는 경우를 위해 −1e−9까지 허용한다.
 * @param {{width:number,height:number}[]} sizes
 */
export function decideDirection(sizes) {
  if (!sizes.length) throw new RangeError('sizes must not be empty');
  const sum = sizes.reduce((acc, s) => acc + Math.log(s.width / s.height), 0);
  return sum >= -1e-9 ? LayoutDirection.vertical : LayoutDirection.horizontal;
}
