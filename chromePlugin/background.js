// 도구 모음 아이콘을 누르면 앱 페이지를 새 탭으로 연다. 이미 열려 있으면 그 탭으로 옮겨 간다.
// 탭을 둘 열면 한쪽이 시작할 때 다른 쪽의 진행 중 세션을 비정상 종료로 바꿔 버린다.
chrome.action.onClicked.addListener(async () => {
  const url = chrome.runtime.getURL('app.html');
  const contexts = await chrome.runtime.getContexts({ contextTypes: ['TAB'], documentUrls: [url] });
  const open = contexts.find((context) => context.tabId >= 0);
  if (!open) {
    await chrome.tabs.create({ url });
    return;
  }
  await chrome.tabs.update(open.tabId, { active: true });
  await chrome.windows.update(open.windowId, { focused: true });
});
