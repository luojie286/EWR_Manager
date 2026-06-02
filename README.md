# EWR_Manager

EWR_Manager（娱乐作品感想管理系统）：基于 Qt Quick（QML）与 C++ 开发的个人娱乐作品管理软件，支持**动漫**与**游戏**的收藏、评分、标签分类、状态管理、感想记录，以及 Bangumi 搜索导入。

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
- 封面图片（本地选择或 Bangumi 自动下载）
- 暗色主题 UI、卡片浏览、空状态提示

### P2（部分实现）

- Bangumi 搜索导入（动漫 type=2、游戏 type=4；标题、简介、标签、评分、封面）
- Bangumi 本地同步（补全已关联 BGM ID 但缺少封面的条目）
- MAL 收藏同步
- 云同步
- 导出 Excel
- 更丰富的统计图表

## 技术栈

- **Qt 6** + **Qt Quick (QML)**
- **C++17**
- **SQLite**（Qt SQL 模块）
- **Bangumi API**（搜索与条目详情）
- 图标：[Lucide Icons](https://github.com/lucide-icons/lucide)（MIT）

## 项目结构

```
├── CMakeLists.txt
├── resources.qrc
├── scripts/
│   └── deploy.ps1             # 手动打包 Qt 运行时（双击 exe 用）
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
│   └── BangumiClient.*        # Bangumi 搜索 / 导入 / 同步
└── qml/
    ├── main.qml
    ├── AppTheme/              # Theme.qml 主题 singleton
    ├── components/            # AnimeCard、ActionButton、BangumiSearchDialog 等
    └── pages/                 # HomePage、DetailPage、EditPage、ReviewPage、StatisticsPage
```

## 数据库表

| 表名            | 说明                                                           |
| ------------- | ------------------------------------------------------------ |
| `anime`       | 动漫：id, title, score, status, description, cover_path, bgm_id |
| `review`      | 动漫感想：id, anime_id, date, title, content                      |
| `game`        | 游戏：id, title, score, status, description, cover_path, bgm_id |
| `game_review` | 游戏感想：id, game_id, date, title, content                       |
| `tag`         | 标签：id, name                                                  |
| `anime_tag`   | 动漫-标签关联                                                      |
| `game_tag`    | 游戏-标签关联                                                      |

数据库文件：`%APPDATA%/Personal/EWR_Manager/anime.db`  
封面缓存：`%APPDATA%/Personal/EWR_Manager/covers/`

## 构建要求

- Qt 6.5+（模块：Qt Quick, Qt SQL, Qt Network, Qt Quick Controls 2, Qt Quick Dialogs, Qt Svg）
- CMake 3.16+
- C++17 编译器（MSVC / MinGW / Clang）

## 构建与运行（Windows）

### 方式一：Qt Creator（推荐）

1. 打开 Qt Creator，选择 `CMakeLists.txt`
2. Kit：**Desktop Qt 6.10.2 MinGW 64-bit**（或 MSVC 2022 64-bit）
3. 构建并运行

构建完成后会自动将 Qt 运行时、`sqldrivers/qsqlite.dll`、图片插件等复制到 exe 同目录，**可直接双击 exe 运行**。

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

### 手动部署（可选）

若 exe 提示缺少 `Qt6Core.dll` 等，或对已有 exe 单独打包：

```powershell
.\scripts\deploy.ps1
# 或指定路径
.\scripts\deploy.ps1 -ExePath "E:\myproject\EWR_Manager\build\Desktop_Qt_6_10_2_MinGW_64_bit-Debug\EWR_Manager.exe"
```

脚本会调用 `windeployqt` 并复制 SQLite / 图片插件及 MinGW 运行库。

## 使用说明

1. 首次启动写入示例数据：6 部动漫（含芙莉莲三条感想）、5 款游戏
2. 顶栏 **动漫 / 游戏** 切换库；**统计** 可分别查看两类数据
3. 首页：搜索、状态筛选、标签筛选、卡片墙浏览
4. 点击卡片 → 详情（简介、标签、感想）；**编辑 / 删除** 在顶栏右侧
5. **添加作品 / 添加游戏** 或卡片编辑按钮 → 编辑页；支持 **从 Bangumi 搜索** 自动填充
6. 详情页 **写感想** 可添加多条记录
7. 卡片封面以完整比例显示（2:3）；无封面时显示占位图

## 页面导航

```
顶栏：动漫 | 游戏 | 统计 | 添加

HomePage ──点击条目──> DetailPage ──写感想──> ReviewPage
    │                      │
    └──添加/编辑──> EditPage  └──编辑──> EditPage

HomePage ──统计──> StatisticsPage（动漫 / 游戏切换）
```

## 常见问题

| 现象                | 处理                                              |
| ----------------- | ----------------------------------------------- |
| 找不到 `Qt6Core.dll` | 在 Qt Creator 中重新构建，或运行 `scripts/deploy.ps1`     |
| `QSQLITE` 驱动不可用   | 确认 exe 同目录存在 `sqldrivers/qsqlite.dll`（构建后会自动复制） |
| Bangumi 搜索无结果     | 检查网络；游戏与动漫使用不同条目类型，请在对应分区搜索                     |
