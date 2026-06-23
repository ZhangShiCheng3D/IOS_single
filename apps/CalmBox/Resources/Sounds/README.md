# 音频资源说明 / Audio Assets

本目录用于存放 App 所需的音频文件。**这些是占位说明，需在 Xcode 中导入真实音频后再上架。**

## 白噪音循环音频（无缝循环，建议 m4a / AAC，时长 1–3 分钟）

| 文件名 | 声源 | 是否付费 |
|--------|------|----------|
| `rain.m4a` | 雨声 | 免费 |
| `fire.m4a` | 炉火 | 免费 |
| `waves.m4a` | 海浪 | 付费 |
| `forest.m4a` | 森林 | 付费 |
| `thunder.m4a` | 雷雨 | 付费 |
| `wind.m4a` | 风声 | 付费 |
| `stream.m4a` | 溪流 | 付费 |
| `night.m4a` | 夏夜虫鸣 | 付费 |

> 循环音频务必做**首尾无缝**处理（zero-crossing 裁剪），否则循环处会有"咔哒"声。

## 短音效（建议 caf / 短促，<1 秒）

| 文件名 | 用途 |
|--------|------|
| `pop.caf` | 泡泡破裂 |
| `spin_tick.caf` | 陀螺旋转 tick |
| `chime.caf` | 计时/呼吸完成提示音 |

## 导入步骤

1. 在 Xcode 中将本 `Sounds` 文件夹拖入项目，选择 **Create folder references**（蓝色文件夹），
   以保留 `subdirectory: "Sounds"` 的查找路径。
2. 确认所有音频文件已勾选 **Target Membership: CalmBox**。
3. 代码通过 `Bundle.main.url(forResource:withExtension:subdirectory:)` 查找，找不到时会自动回退到根目录。

## 版权提示

上架前请确保所有音频拥有**商用授权**（CC0 / 自录 / 已购授权）。推荐来源：
- freesound.org（注意逐个确认许可证）
- 自行录制（最安全）
