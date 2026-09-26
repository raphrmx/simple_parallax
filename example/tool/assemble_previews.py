"""Turns the frames record_previews.dart wrote into the animated WebP previews.

Run it from the example directory, after the recorder:

    flutter test tool/record_previews.dart
    python tool/assemble_previews.py

The frames are rendered at twice the final size, so halving them here averages
four pixels into one and keeps the text and the image edges clean.
"""

import io
import os
import sys

from PIL import Image

SIZE = (520, 260)
FPS = 25
QUALITY = 80

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
frames_root = os.path.join(root, 'build', 'previews')
out_root = os.path.abspath(os.path.join(root, '..', 'doc'))

if not os.path.isdir(frames_root):
    sys.exit('no frames in %s, run the recorder first' % frames_root)

for name in sorted(os.listdir(frames_root)):
    folder = os.path.join(frames_root, name)
    if not os.path.isdir(folder):
        continue
    files = sorted(f for f in os.listdir(folder) if f.endswith('.png'))
    if not files:
        continue

    frames = []
    for f in files:
        im = Image.open(os.path.join(folder, f)).convert('RGBA')
        flat = Image.new('RGB', im.size, (255, 255, 255))
        flat.paste(im, mask=im.split()[3])
        frames.append(flat.resize(SIZE, Image.LANCZOS))

    out = os.path.join(out_root, name + '.webp')
    frames[0].save(
        out,
        'WEBP',
        save_all=True,
        append_images=frames[1:],
        duration=int(round(1000.0 / FPS)),
        loop=0,
        quality=QUALITY,
        method=6,
        # Every frame a key frame: left to blend, the encoder ghosts the text
        # of the frame before onto the one after.
        kmin=1,
        kmax=1,
    )
    print('%-28s %d frames  %d Ko' % (name, len(frames),
                                      os.path.getsize(out) // 1024))
