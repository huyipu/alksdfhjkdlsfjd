// 图标生成脚本：baitian.png（白天）/ heiye.png（黑夜）→ iOS + Android 全套启动图标
// 用法: node gen_icons.cjs   （在 tlbb_app 目录下运行，依赖 ../tlbb-admin/node_modules/sharp）
const sharp = require('../tlbb-admin/node_modules/sharp');
const fs = require('fs');
const path = require('path');

const SRC_LIGHT = 'baitian.png';
const SRC_DARK = 'heiye.png';

async function main() {
  // ---------- iOS ----------
  const setDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  const contentsPath = path.join(setDir, 'Contents.json');
  const contents = JSON.parse(fs.readFileSync(contentsPath, 'utf8'));

  // 只处理基础槽位（不含 dark 变体），重建 images 数组
  const baseImages = contents.images.filter((i) => !i.appearances);
  const images = [];
  for (const img of baseImages) {
    const px = Math.round(parseFloat(img.size) * parseInt(img.scale));
    // 白天图（不透明，无 alpha，App Store 要求）
    await sharp(SRC_LIGHT).resize(px, px).flatten({ background: '#ffffff' }).png()
      .toFile(path.join(setDir, img.filename));
    images.push(img);
    // iOS 18+ 深色外观：每个槽位都配 dark appearance 变体（只配 1024 主屏幕不会切换）
    const darkName = img.filename.replace('@', '-dark@');
    await sharp(SRC_DARK).resize(px, px).flatten({ background: '#000000' }).png()
      .toFile(path.join(setDir, darkName));
    images.push({
      size: img.size,
      idiom: img.idiom,
      filename: darkName,
      scale: img.scale,
      appearances: [{ appearance: 'luminosity', value: 'dark' }],
    });
  }
  contents.images = images;
  fs.writeFileSync(contentsPath, JSON.stringify(contents, null, 2) + '\n');
  console.log('iOS 图标完成（全槽位含深色变体）');

  // ---------- Android ----------
  // 背景色取白天图左上角像素（图标自身底色），保证遮罩裁切后颜色无缝
  const { data } = await sharp(SRC_LIGHT).raw().toBuffer({ resolveWithObject: true });
  const bg = '#' + [data[0], data[1], data[2]].map((v) => v.toString(16).padStart(2, '0')).join('');
  const colorsPath = 'android/app/src/main/res/values/colors.xml';
  let colors = fs.readFileSync(colorsPath, 'utf8');
  colors = colors.replace(/<color name="ic_launcher_background">#[0-9A-Fa-f]{6}<\/color>/,
    `<color name="ic_launcher_background">${bg}</color>`);
  fs.writeFileSync(colorsPath, colors);
  console.log('Android 背景色:', bg);

  const densities = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
  const fgSizes = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };
  for (const d of Object.keys(densities)) {
    const dir = `android/app/src/main/res/mipmap-${d}`;
    // 传统图标：整张白天图直接缩放
    await sharp(SRC_LIGHT).resize(densities[d], densities[d]).png()
      .toFile(path.join(dir, 'ic_launcher.png'));
    // 自适应前景：透明画布 + 图标缩到 75%（安全区内，圆角遮罩不裁内容）
    const fg = fgSizes[d];
    const inner = Math.round(fg * 0.75);
    const resized = await sharp(SRC_LIGHT).resize(inner, inner).png().toBuffer();
    await sharp({
      create: { width: fg, height: fg, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
    }).composite([{ input: resized, left: Math.round((fg - inner) / 2), top: Math.round((fg - inner) / 2) }])
      .png().toFile(path.join(dir, 'ic_launcher_foreground.png'));
  }
  console.log('Android 图标完成');
}

main().catch((e) => { console.error(e); process.exit(1); });
