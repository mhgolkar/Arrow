# Arrow 繁體中文社群版代理指引

本儲存庫是 Arrow 的台灣繁體中文翻譯與社群維護版本。所有修改應維持與英文原版之間的可逆切換，並盡量降低與上游合併時的衝突。

## 使用者介面語言

- 所有代理產生、會顯示給使用者的授權或權限請求文字，使用台灣繁體中文（zh-TW）。
- 這包含提權理由、核准問題、風險說明、拒絕或取消原因，以及相關等待或狀態訊息。
- 不翻譯命令、參數、檔案路徑、程式碼、設定鍵、工具名稱及權限列舉值；必要時以反引號保留原文。

## 翻譯原則

- 英文 `msgid` 是原始識別內容，不可直接覆寫；繁中內容放在 `msgstr`。
- 主要介面翻譯位於 `assets/translations/zh_TW.po`。
- 節點專屬翻譯位於 `nodes/<type>/translations/zh_TW.po`。
- 動態建立的文字必須經過 Godot 的 `tr()`，並在相應 PO 檔提供翻譯。
- 人名、專案名稱、商標、程式碼、檔案路徑與法律授權名稱通常保留原文。
- 用語以台灣軟體介面的自然表達為優先，並維持全專案一致。
- `Inspector` 在本專案統一譯為「屬性面板」。
- 修改 PO 檔後，必須用 Godot 重新匯入並確認沒有解析錯誤。

## 字型

- 繁體中文「跟隨語言」預設字型是 `assets/fonts/NotoSansCJKtc-Medium.otf`。
- 偏好設定中的 `Traditional Chinese Default` 標記必須與上述預設一致。
- 介面字型由 `assets/fonts` 動態列出，並允許使用者瀏覽外部字型。
- 新增或移除隨附字型時，必須同步更新 `assets/fonts/copyright` 與 `assets/fonts/copyright.zh_TW`。
- 僅能隨附授權允許重新散布的字型；不得加入來源或散布權不明的字型。

## 法律與著作權

- 不修改或刪除原始 `license`、`copyright` 及其既有法律內容。
- 繁中參考譯文使用獨立檔案，例如 `license.zh_TW`、`copyright.zh_TW` 與 `godot_license.zh_TW`。
- 中文譯文不取代具有法律效力的英文原文。
- 新增的第三方內容必須保留來源、作者、授權與必要的散布聲明。

## Godot 與本機建置

- 專案使用 Godot 4.7 stable，主場景是 `res://main.tscn`。
- 修改翻譯、字型、場景或腳本後，先執行 headless editor 匯入：

```powershell
& 'G:\Desktop\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64.exe' --headless --editor --path 'O:\Github Repositories\Arrow' --quit
```

- Windows release 建置命令：

```powershell
& 'G:\Desktop\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64.exe' --headless --path 'O:\Github Repositories\Arrow' --export-release 'Windows' 'O:\Github Repositories\Arrow\build\windows\Arrow.exe'
```

- Windows 成品需要同時保留 `Arrow.exe` 與 `Arrow.pck`。
- `export_presets.cfg` 的 Windows 圖示使用 `res://icon.svg`，並需保持 `application/modify_resources=true`。
- `assets/translations` 中的參考截圖不應提交或打包；檢查完成後由使用者移除，再重新建置。
- 沙箱環境可能無法讀取系統根憑證或寫入 Godot 編輯器設定；若匯出已完成，這類既有警告不等同建置失敗。

## GitHub Actions

- 所有建置 workflow 僅使用 `workflow_dispatch` 手動啟動，不因 push 或 Pull Request 自動執行。
- `Build Desktop` 同時呼叫 Windows 與 Linux 的可重複使用 workflow。
- `Build Windows` 與 `Build Linux` 可各自獨立執行。
- Windows Artifact 必須包含 `Arrow.exe` 與 `Arrow.pck`。
- Linux Artifact 必須包含 `Arrow.x86_64`、`Arrow.pck`，以及保留執行權限的 `tar.gz`。
- GitHub JavaScript Actions 使用支援 Node.js 24 的版本，目前為 `actions/checkout@v6` 與 `actions/upload-artifact@v7`。

## Git 與工作區安全

- 既有或不相關的修改視為使用者內容，不可任意還原、覆蓋或刪除。
- 工作樹混有不同範圍的變更時，只暫存本次任務相關檔案，不使用未確認範圍的 `git add -A`。
- 提交前執行 `git diff --check`，並依修改風險完成 Godot 匯入或 release 建置。
- 不使用 `git reset --hard`、`git checkout --` 或其他破壞性還原命令，除非使用者明確要求。
- 功能分支推送後，需合併至預設分支 `main`，GitHub 才會從 Actions 頁面顯示新增的手動 workflow。
