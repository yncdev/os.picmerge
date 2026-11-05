/** 저장·공유 한 번의 단계. */
export const JobPhase = Object.freeze({
  idle: 'idle',
  /** 저장 폴더 권한을 확인하는 중이다. 아직 아무것도 만들지 않았다. */
  preparing: 'preparing',
  /** 합성하거나 고른 폴더에 쓰는 중이다. */
  merging: 'merging',
  /** 결과가 나왔고 기록도 남았다. 공유 창이나 오류 창이 닫히기를 기다린다. */
  finished: 'finished',
});

/**
 * 지금 탭을 떠나면 결과를 잃는가. 합성과 폴더 쓰기 중에만 참이다.
 * 공유 창이 열려 있을 때 참이면 '메일 작성'의 mailto: 링크와 새로 고침이 떠나기 확인 창을 띄운다.
 */
export function losesWorkOnLeave(phase) {
  return phase === JobPhase.merging;
}
