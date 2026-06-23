"""生成 CalmBox 1024×1024 AppIcon — 深蓝紫渐变背景 + 同心圆声波纹。"""
from PIL import Image, ImageDraw

S = 1024


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main():
    top = (0x2D, 0x30, 0x47)      # 深蓝紫 #2D3047
    bottom = (0x41, 0x91, 0xE1)   # 紫蓝 #4191E1

    # 4× 超采样以获得平滑边缘，最终缩放回 1024
    scale = 4
    size = S * scale
    img = Image.new("RGB", (size, size))
    px = img.load()

    # 对角渐变（左上 -> 右下）
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = lerp(top, bottom, t)

    draw = ImageDraw.Draw(img, "RGBA")
    cx = cy = size / 2

    # 同心圆波纹：白色，越往外越透明
    rings = 5
    max_r = size * 0.40
    line_w = max(2, int(size * 0.012))
    for i in range(rings):
        r = max_r * (i + 1) / rings
        alpha = int(220 * (1 - i / rings))  # 内圈亮，外圈淡
        bbox = [cx - r, cy - r, cx + r, cy + r]
        draw.ellipse(bbox, outline=(255, 255, 255, alpha), width=line_w)

    # 中心实心圆点（声源）
    dot_r = max_r * 0.10
    draw.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r],
                 fill=(255, 255, 255, 255))

    img = img.resize((S, S), Image.LANCZOS)

    out = ("C:/Users/m1770/Desktop/商业项目/IOS_single/apps/CalmBox/"
           "Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
    # 24bpp RGB，无 alpha 通道
    img.save(out, "PNG")
    print("saved:", out, img.mode, img.size)


if __name__ == "__main__":
    main()
