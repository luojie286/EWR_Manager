# EWR_Manager

EWR_Manager（娱乐作品感想管理系统）：基于 Qt Quick（QML）与 C++ 开发的个人娱乐作品管理软件，支持**动漫**与**游戏**的收藏、评分、标签分类、状态管理、感想记录、Bangumi / RAWG 搜索导入，以及背景音乐播放。

## 功能概览

### P0（已实现）

- 动漫 / 游戏：添加、删除、查看、编辑
- 多条感想记录（日期、标题、内容）
- SQLite 本地持久化

### P1（已实现）

- 标签系统（自定义标签 + 标签筛选）
- 搜索（标题、简介）
- 状态管理
  - 动漫：未看 / 在看 / 看完 / 弃坑
  - 游戏：未玩 / 在玩 / 玩完 / 弃坑
- 数据统计（数量、平均分、标签排行榜；动漫 / 游戏分开展示）
- 封面图片（本地选择或 Bangumi / RAWG 自动下载）
- 首页**批量选择与批量删除**
- 暗色主题 UI、PS4 风格粒子背景、卡片浏览、空状态提示
- **背景音乐**：随机播放、静音、播放列表管理；有内嵌封面时叠加显示在背景上

### P2（部分实现）

- Bangumi 搜索导入（动漫 / 游戏补充）
- RAWG 搜索导入（游戏主数据源，含封面、评分与自动中文翻译）
- Bangumi 本地同步（补全已关联 BGM ID 但缺少封面的条目）
- 横版游戏封面智能裁剪（`CoverImage` 组件）
- MAL 收藏同步
- 云同步
- 导出 Excel
- 更丰富的统计图表

## 技术栈

- **Qt 6** + **Qt Quick (QML)**
- **C++17**
- **SQLite**（Qt SQL 模块）
- **Qt Multimedia**（背景音乐播放）
- **Bangumi API**（搜索与条目详情）
- **RAWG API**（游戏搜索与导入）
- 图标：[Lucide Icons](https://github.com/lucide-icons/lucide)（MIT）

## 项目结构

```
├── CMakeLists.txt
├── resources.qrc
├── scripts/
│   ├── deploy.ps1             # 手动打包 Qt 运行时（双击 exe 用）
│   └── run.ps1                # 部署并启动
├── resources/
│   └── icons/                 # SVG 图标资源
├── src/
│   ├── main.cpp
│   ├── DatabaseManager.*      # SQLite 数据层
│   ├── AnimeController.*      # 动漫业务接口
│   ├── AnimeListModel.*
│   ├── ReviewListModel.*
│   ├── GameController.*       # 游戏业务接口
│   ├── GameListModel.*
│   ├── GameReviewListModel.*
│   ├── BangumiClient.*        # Bangumi 搜索 / 导入 / 同步
│   ├── RawgClient.*           # RAWG 游戏搜索 / 导入 / 翻译
│   └── MusicController.*      # 背景音乐播放 / 封面提取
└── qml/
    ├── main.qml
    ├── AppTheme/              # Theme.qml 主题 singleton
    ├── components/            # AnimeCard、CoverImage、MusicPlayerBar、ParticleBackground 等
    └── pages/                 # HomePage、DetailPage、EditPage、ReviewPage、StatisticsPage
```

## 数据与文件路径

| 路径 | 说明 |
| --- | --- |
| `%APPDATA%/Personal/EWR_Manager/anime.db` | SQLite 数据库 |
| `%APPDATA%/Personal/EWR_Manager/covers/` | 动漫 / 游戏封面缓存 |
| `%APPDATA%/Personal/EWR_Manager/music/` | 背景音乐文件夹（放入音频即可扫描） |
| `%APPDATA%/Personal/EWR_Manager/music/.covers/` | 音乐内嵌封面缓存 |

### 数据库表

| 表名 | 说明 |
| --- | --- |
| `anime` | 动漫：id, title, score, status, description, cover_path, bgm_id |
| `review` | 动漫感想：id, anime_id, date, title, content |
| `game` | 游戏：id, title, score, status, description, cover_path, bgm_id |
| `game_review` | 游戏感想：id, game_id, date, title, content |
| `tag` | 标签：id, name |
| `anime_tag` | 动漫-标签关联 |
| `game_tag` | 游戏-标签关联 |
| `app_settings` | 应用设置（如示例数据是否已写入） |

## 构建要求

- Qt 6.5+（模块：Qt Quick, Qt SQL, Qt Network, Qt Multimedia, Qt Quick Controls 2, Qt Quick Dialogs, Qt Svg）
- CMake 3.16+
- C++17 编译器（MSVC / MinGW / Clang）

## 构建与运行（Windows）

### 方式一：Qt Creator（推荐）

1. 打开 Qt Creator，选择 `CMakeLists.txt`
2. Kit：**Desktop Qt 6.10.2 MinGW 64-bit**（或 MSVC 2022 64-bit）
3. 构建并运行

构建完成后会自动将 Qt 运行时、`sqldrivers/qsqlite.dll`、Multimedia 插件、图片插件等复制到 exe 同目录，**可直接双击 exe 运行**。

### 方式二：命令行

```powershell
$env:PATH = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.10.2\mingw_64\bin;C:\Qt\Tools\CMake_64\bin;" + $env:PATH
$env:CMAKE_PREFIX_PATH = "C:\Qt\6.10.2\mingw_64"

mkdir build -Force
cd build
cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j 4

.\EWR_Manager.exe
```

### 一键部署并启动

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run.ps1
```

### 手动部署（可选）

若 exe 提示缺少 `Qt6Core.dll` 等，或对已有 exe 单独打包：

```powershell
.\scripts\deploy.ps1
# 或指定路径
.\scripts\deploy.ps1 -ExePath "E:\myproject\EWR_Manager\build\EWR_Manager.exe"
```

脚本会调用 `windeployqt` 并复制 SQLite / Multimedia / 图片插件及 MinGW 运行库。

## 使用说明

### 作品管理

1. **仅首次安装**写入示例数据：6 部动漫（含芙莉莲三条感想）、5 款游戏；删光作品后重启**不会**再自动恢复示例
2. 顶栏 **动漫 / 游戏** 切换库；**统计** 可分别查看两类数据
3. 首页：搜索、状态筛选、标签筛选、卡片墙浏览；右上角可进入**批量模式**多选删除
4. 点击卡片 → 详情（简介、标签、感想）；**编辑 / 删除** 在顶栏右侧
5. **添加作品 / 添加游戏** → 编辑页
   - 动漫：**从 Bangumi 搜索**
   - 游戏：**从 RAWG 搜索**（主）或 **从 Bangumi 搜索**（日系 / 中文条目补充）
6. 首次使用 RAWG 需在搜索框填写 [RAWG API Key](https://rawg.io/apidocs)（免费注册），保存后自动记住；可随时 **更改** 或 **清除** Key
7. 详情页 **写感想** 可添加多条记录
8. 卡片封面：竖图完整显示；RAWG 横版封面自动居中裁剪；放不下的标签整枚隐藏，不裁切显示

### 背景音乐

1. 将 mp3、flac、ogg、wav、m4a 等文件放入 `%APPDATA%/Personal/EWR_Manager/music/`
2. 顶栏播放条：**播放 / 暂停**、**随机下一首**、**静音**、**音乐列表**
3. 也可在列表对话框中 **添加文件**、**扫描文件夹**、**打开文件夹**
4. 默认启动后随机播放；音量跟随系统，应用内仅提供静音开关
5. 若音频含内嵌封面，会以与窗口等高的方式半透明叠加在粒子背景上（不替换背景）

## 页面导航

```
顶栏：动漫 | 游戏 | 统计 | [音乐播放条] | 添加

HomePage ──点击条目──> DetailPage ──写感想──> ReviewPage
    │                      │
    └──添加/编辑──> EditPage  └──编辑──> EditPage

HomePage ──统计──> StatisticsPage（动漫 / 游戏切换）
```

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 双击 build 里 exe 没反应 | 先运行 `scripts\run.ps1` 或 `scripts\deploy.ps1`；失败时会弹出错误提示 |
| 找不到 `Qt6Core.dll` | 在 Qt Creator 中重新构建，或运行 `scripts/deploy.ps1` |
| `QSQLITE` 驱动不可用 | 确认 exe 同目录存在 `sqldrivers/qsqlite.dll`（构建后会自动复制） |
| 删光作品重启又出现示例 | 已修复：示例仅在首次安装写入；数据在 `%APPDATA%/Personal/EWR_Manager/anime.db` |
| 统计页标签榜不更新 | 删除作品后统计页会自动刷新；数据层已启用外键并清理孤儿记录 |
| Bangumi 搜索无结果 | 检查网络；游戏与动漫使用不同条目类型，请在对应分区搜索 |
| RAWG 搜索提示缺少 Key | 添加游戏 → **从 RAWG 搜索** → 点 **更改** 或 **清除** 后重新填写 Key |
| RAWG 封面是横版 | 已自动裁剪适配卡片；也可改用 Bangumi 导入或手动换竖版封面 |
| 背景音乐无声音 | 运行 `scripts\deploy.ps1` 确保 Multimedia 插件已部署；检查系统音量与静音键 |
