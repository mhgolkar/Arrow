<img src="./icon.svg" width="64" alt="Arrow 圖示">

# Arrow 繁體中文社群版

Arrow 遊戲敘事設計工具的台灣繁體中文翻譯與社群維護版本。

本專案以 [Mor. H. Golkar 的 Arrow](https://github.com/mhgolkar/Arrow) 為基礎，目標是在不破壞原始英文內容的前提下，提供可切換語言的繁體中文介面、適合中文顯示的字型，以及相關在地化調整。

> [!IMPORTANT]
> 這是非官方社群版本，不代表 Arrow 原作者或官方專案。原版功能、文件與問題回報請以[官方儲存庫](https://github.com/mhgolkar/Arrow)為準。

## 目前版本

- 上游版本：Arrow 3.1.0
- 社群版本標記：`3.1.0-ZhTW-1`
- 翻譯語系：台灣繁體中文（`zh_TW`）
- 中文預設字型：Noto Sans CJK TC Medium

## 社群版內容

- 可在偏好設定中切換英文與台灣繁體中文，翻譯不會覆蓋英文原文。
- 翻譯主要介面、節點、提示訊息、確認視窗與關於頁內容。
- 提供中文授權參考譯文；具有法律效力的條款仍以英文原文為準。
- 內建多款採 SIL Open Font License 1.1 授權的中英文字型。
- 可在偏好設定選擇介面字型，或瀏覽並載入本機字型檔。
- 繁中環境預設使用 Noto Sans CJK TC Medium。
- 關於頁會顯示繁中版本標記及本翻譯專案的儲存庫連結。

Arrow 本身是一套自由、開放原始碼的視覺化遊戲敘事設計工具，可用於文字冒險、互動式非線性故事，以及節點式敘事流程製作。完整功能介紹請參閱[官方 README](https://github.com/mhgolkar/Arrow#readme)與[官方 Wiki](https://github.com/mhgolkar/Arrow/wiki)。

## 取得 Windows 版本

### 從 GitHub Actions 手動建置

1. 開啟本儲存庫的 [Actions](https://github.com/UlinRei/Arrow-zh-tw/actions) 頁面。
2. 依需求選擇 **Build Desktop**（同時建置兩個平台）、**Build Windows** 或 **Build Linux**。
3. 按下 **Run workflow** 並選擇要建置的分支。
4. 等待建置完成後，從該次執行頁面的 **Artifacts** 下載所需平台：
   - `Arrow-3.1.0-ZhTW-1-Windows-x86_64`
   - `Arrow-3.1.0-ZhTW-1-Linux-x86_64`
5. 解壓縮下載的 Artifact，將平台執行檔與 `Arrow.pck` 保持在同一資料夾。Windows 執行 `Arrow.exe`；Linux 建議解壓其中的 `tar.gz` 後執行 `Arrow.x86_64`，以保留執行權限。

Action 只會在使用者手動要求時執行，不會因為推送或 Pull Request 自動建置。產物預設保留 30 天。

### 從原始碼建置

需要 Godot 4.7 stable 與對應的 Windows 匯出模板：

```powershell
godot --headless --editor --path . --quit
godot --headless --path . --export-release "Windows" "build/windows/Arrow.exe"
```

建置完成後，`build/windows` 內的 `Arrow.exe` 與 `Arrow.pck` 必須一起保留。

## 使用與設定

第一次啟動後，可在 **偏好設定 → 語言** 選擇 `Chinese, Taiwan (zh_TW)`。若畫面沒有立即完整更新，關閉並重新開啟偏好設定或重新啟動程式即可。

介面字型選項位於語言設定下方。選擇「跟隨語言」時，繁體中文會使用本專案設定的中文預設字型；也可以選擇內建字型，或使用「瀏覽」加入本機字型。

## 翻譯與貢獻

主要介面翻譯位於 [`assets/translations/zh_TW.po`](./assets/translations/zh_TW.po)，各節點的翻譯位於對應節點資料夾下的 `translations/zh_TW.po`。

歡迎透過 Issue 或 Pull Request 回報與改進：

- 遺漏或不自然的翻譯
- 文字超出介面、換行或字型顯示問題
- 僅在重新啟動後出現的語言設定問題
- 繁中用語一致性與專有名詞建議

修改翻譯時請保留原始 `msgid`，只調整 `msgstr`，以維持英文與繁體中文之間的可逆切換。

## 上游與相容性

本儲存庫會盡可能讓翻譯與社群調整保持獨立，方便追蹤 Arrow 上游更新。由於社群版包含少量介面與設定程式碼調整，更新上游版本時仍可能需要手動處理衝突及重新檢查翻譯。

- 官方儲存庫：[mhgolkar/Arrow](https://github.com/mhgolkar/Arrow)
- 繁中社群儲存庫：[UlinRei/Arrow-zh-tw](https://github.com/UlinRei/Arrow-zh-tw)
- 官方文件：[Arrow Wiki](https://github.com/mhgolkar/Arrow/wiki)
- 官方網頁版：[Arrow Web App](https://mhgolkar.github.io/Arrow/)

官方網頁版由上游專案維護，並不包含本儲存庫的繁體中文修改。

## 授權與字型

Arrow 原始程式由 Mor. H. Golkar 與貢獻者依 MIT License 發布。本翻譯與程式修改沿用專案既有授權；詳情請參閱 [`license`](./license) 與 [`copyright`](./copyright)。

內建字型各自依 SIL Open Font License 1.1 授權，來源、作者與散布說明記錄於 [`assets/fonts/copyright`](./assets/fonts/copyright)；繁中參考內容請見 [`assets/fonts/copyright.zh_TW`](./assets/fonts/copyright.zh_TW)。字型名稱及商標僅用於識別與標示來源，不代表其作者為本社群版本背書。
