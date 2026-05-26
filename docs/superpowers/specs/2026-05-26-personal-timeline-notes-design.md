# 个人时间线笔记 — 设计规格

**日期：** 2026-05-26
**平台：** iOS 17+，SwiftUI + SwiftData
**类型：** 纯本地时间线笔记应用

## 概述

一款 iOS 个人时间线笔记应用。像 X/Twitter 一样发布短笔记，按时间线浏览，支持图片、视频和标签。纯本地存储。架构为未来社交功能预留扩展空间。

## 架构

**方案 C：务实平衡型**

- SwiftData `@Model` 负责持久化
- 轻量 Service 层（`NoteService`、`TimelineService`、`TagService`、`MediaService`）封装核心操作
- View 层用 `@Query` 做简单读取；复杂查询（搜索、多条件筛选）走 Service
- Repository 协议预留接口但不实现，待未来后端迁移时启用
- 不引入 ViewModel 层 — Service 作为 View 和数据之间的边界

## 数据模型

### 时间线（Timeline）
| 字段 | 类型 | 说明 |
|-------|------|-------|
| id | UUID | 主键 |
| name | String | 显示名称 |
| icon | String | SF Symbol 图标名 |
| color | String | 预设主题色 |
| sortOrder | Int | 手动排序 |
| createdAt | Date | 创建时间 |
| notes | [Note] | 一对多 |

### 笔记（Note）
| 字段 | 类型 | 说明 |
|-------|------|-------|
| id | UUID | 主键 |
| content | String | 正文，不限制字数 |
| createdAt | Date | 创建时间 |
| editedAt | Date? | 编辑时间，未编辑则为 nil |
| timeline | Timeline? | 所属时间线，可空 = 全局笔记 |
| tags | [Tag] | 多对多 |
| media | [MediaAttachment] | 一对多，按 order 排序 |
| isPinned | Bool | 是否置顶 |

### 标签（Tag）
| 字段 | 类型 | 说明 |
|-------|------|-------|
| id | UUID | 主键 |
| name | String | 小写，不含 `#` 前缀 |
| notes | [Note] | 多对多反向关系 |

### 媒体附件（MediaAttachment）
| 字段 | 类型 | 说明 |
|-------|------|-------|
| id | UUID | 主键 |
| type | MediaType | `.image` 或 `.video` |
| fileName | String | 存储于 App Documents/Media/ |
| thumbnailFileName | String? | 压缩缩略图 |
| order | Int | 在笔记中的展示顺序 |
| note | Note | 反向关系 |

## 数据存储

- 所有模型对象使用 SwiftData 存储
- 媒体文件：`App/Documents/Media/<uuid>.<ext>`，缩略图：`App/Documents/Media/thumb_<uuid>.<ext>`
- 图片压缩：保留原图，缩略图生成 400px 最大尺寸用于时间线展示
- 不依赖任何第三方库，仅使用 iOS 原生框架

## 导航与页面结构

```
TabView
├── 时间线 Tab（主页）
│   ├── 顶部：时间线横向滚动选择器（末尾 "+" 新建）
│   ├── 主体：垂直笔记流（类 Twitter 时间线）
│   ├── 下拉刷新、上滑分页加载
│   ├── 笔记卡片：正文 + 媒体网格 + 标签 + 时间戳
│   ├── 滑动/长按操作：编辑、删除、移动至其他时间线
│   └── 右下角 FAB：快速发笔记
├── 搜索 Tab
│   ├── 顶部搜索栏（全文搜索）
│   ├── 标签云 / 热门标签
│   ├── 筛选条件：时间范围、标签、时间线
│   └── 搜索结果列表
└── 设置 Tab
    ├── 时间线管理（排序、删除、重命名、图标颜色）
    ├── 数据导出（JSON + 媒体文件）
    └── 关于
```

### 笔记详情页（Push 导航）
- 全屏展示
- 大图浏览，支持双指缩放，可保存到相册
- 视频播放器（原生控件）
- 点击 `#hashtag` → 跳转搜索该标签
- `···` 菜单：编辑、删除、更换时间线、复制正文

### 发布/编辑笔记（Sheet 弹出）
- 文本编辑器，不限字数
- 多选图片/视频选择器（PhotosUI PHPicker）
- 标签选择器：选择已有标签 + 新建标签
- 时间线选择器
- 发布 / 保存按钮

## 媒体网格布局

| 图片数量 | 布局方式 |
|-------------|--------|
| 1 张 | 全宽展示 |
| 2 张 | 两列等宽 |
| 3 张及以上 | 三列正方形网格，多余图片补最后一行 |

视频缩略图叠加播放图标和时长标记。

## Hashtag 系统

- 保存笔记时从正文中提取 `#hashtag`，正则 `/#([\p{L}\p{N}_-]+)/`
- 自动创建 Tag 对象并与笔记关联
- 编辑笔记时：正文中删除的 hashtag 解除关联，新增的自动添加
- 正文中渲染为蓝色可点击文字
- 发布页提供独立标签字段，手动管理标签
- 标签跨时间线共享 — 标签「工作」能查到所有时间线下的相关笔记

## 搜索与筛选

- 全文搜索：基于 `Note.content` 使用 `NSPredicate`（SwiftData 支持 CONTAINS）
- 未来可选：引入 NaturalLanguage 框架提升搜索质量
- 标签筛选：选择一个或多个标签，支持 AND/OR 逻辑
- 时间范围筛选：预设范围（今天、本周、本月）+ 自定义日期选择
- 组合筛选：所有条件可叠加（文本 + 标签 + 时间范围）

## 未来扩展点

以下接口仅预留，V1 不实现：
- `NoteRepository` 协议 — 用于日后把 SwiftData 替换为远程 API
- `SyncService` 协议 — CloudKit / 自建服务端同步
- 社交模型占位（用户资料、关注关系、共享时间线）

## 测试策略

- `NoteService`、`TimelineService`、`TagService` 使用内存 SwiftData 容器进行单元测试
- 媒体网格布局逻辑可抽为纯函数，便于单元测试
- Hashtag 解析正则单独测试
- UI 通过模拟器 / 真机手动验证（自动化 UI 测试可选）
- 时间线卡片渲染快照测试（可选，需引入 SnapshotTesting 库）

## V1 不做

- 云端同步 / 多设备
- 社交 / 分享功能
- Widget 小组件
- Siri 捷径 / 快捷指令集成
- 深色模式（跟随系统主题即可）
- iPad 适配（iPhone 优先）
- 多语言（仅中文界面）
- 数据加密 / Face ID 锁定
