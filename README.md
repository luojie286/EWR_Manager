# EWR_Manager

EWR_Manager（娱乐作品感想管理系统）：基于 Qt Quick（QML）与 C++ 开发的个人作品管理软件，实现娱乐作品的收藏、评分、标签分类、状态管理及多次感想记录等功能。

## 功能概览

### P0（已实现）
- 添加 / 删除 / 查看 / 编辑作品
- 多条感想记录（日期、标题、内容）
- SQLite 本地持久化

### P1（已实现）
- 标签系统（自定义标签 + 标签筛选）
- 搜索（作品名、简介）
- 观看状态管理（未看 / 在看 / 看完 / 弃坑）
- 数据统计（作品数、平均分、标签排行）
- 封面图片（FileDialog 选择本地路径）

### P2（部分实现）
- Bangumi 搜索导入（标题、简介、标签、评分、封面下载）
- Bangumi / MAL 收藏同步
- 云同步
- 导出 Excel
- 统计图表

## 技术栈

- **Qt 6** + **Qt Quick (QML)**
- **C++17**
- **SQLite**（Qt SQL 模块）

## 项目结构

```
├── CMakeLists.txt
├── resources.qrc
├── src/
│   ├── main.cpp
│   ├── DatabaseManager.*      # SQLite 数据层
│   ├── AnimeListModel.*       # 作品列表 Model/View
│   ├── ReviewListModel.*      # 感想列表 Model/View
│   └── AnimeController.*      # QML 业务接口
└── qml/
    ├── main.qml
    ├── AppTheme/              # 主题 singleton
    ├── components/            # 可复用组件
    └── pages/                 # 页面
        ├── HomePage.qml
        ├── DetailPage.qml
        ├── EditPage.qml
        ├── ReviewPage.qml
        └── StatisticsPage.qml
```

## 数据库表

| 表名 | 字段 |
|------|------|
| `anime` | id, title, score, status, description, cover_path, bgm_id |
| `review` | id, anime_id, date, title, content |
| `tag` | id, name |
| `anime_tag` | anime_id, tag_id |

数据库文件位置：`%APPDATA%/Personal/EWR_Manager/anime.db`  
封面缓存目录：`%APPDATA%/Personal/EWR_Manager/covers/`

## 构建要求

- Qt 6.5+（需安装模块：Qt Quick, Qt SQL, Qt Quick Controls 2, Qt Quick Dialogs）
- CMake 3.16+
- C++17 编译器（MSVC / MinGW / Clang）

## 构建步骤（Windows）

### 方式一：Qt Creator（推荐）

1. 打开 Qt Creator
2. **文件 → 打开文件或项目**，选择 `CMakeLists.txt`
3. 选择 Kit：**Desktop Qt 6.10.2 MinGW 64-bit**（或 MSVC 2022 64-bit）
4. 点击左下角 **运行**（绿色三角）

### 方式二：命令行

```powershell
$env:PATH = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.10.2\mingw_64\bin;C:\Qt\Tools\CMake_64\bin;" + $env:PATH
$env:CMAKE_PREFIX_PATH = "C:\Qt\6.10.2\mingw_64"

cd build
cmake -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j 4

# 运行
.\EWR_Manager.exe
```

## 使用说明

1. 首次启动会自动写入 6 部示例作品（含芙莉莲的三条感想）
2. 首页：搜索、状态筛选、标签筛选、卡片墙浏览
3. 点击卡片进入详情，可查看简介、标签、感想列表
4. 「+ 添加作品」或卡片上的编辑按钮进入编辑页；编辑页可 **从 Bangumi 搜索** 自动填充信息并下载封面
5. 详情页「写感想」可为一个作品添加多条记录
6. 顶部「统计」查看数据概览与标签排行榜

## 页面导航

```
HomePage ──点击作品──> DetailPage ──写感想──> ReviewPage
    │                      │
    └──添加/编辑──> EditPage  └──编辑──> EditPage
    
HomePage ──统计──> StatisticsPage
```
