// RedMode: toggles a full-screen "night vision" red filter, plus red mouse pointers.
// Run once = red on. Run again = red off (normal colours and pointers restored).
using System;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

static class RedMode
{
    // ---- Screen colour filter (Magnification API) ----
    [DllImport("Magnification.dll")] static extern bool MagInitialize();
    [DllImport("Magnification.dll")] static extern bool MagUninitialize();
    [DllImport("Magnification.dll")] static extern bool MagSetFullscreenColorEffect(float[] matrix);

    // ---- Cursor plumbing ----
    [StructLayout(LayoutKind.Sequential)]
    struct ICONINFO { public bool fIcon; public int xHotspot; public int yHotspot; public IntPtr hbmMask; public IntPtr hbmColor; }

    [StructLayout(LayoutKind.Sequential)]
    struct BITMAP { public int bmType, bmWidth, bmHeight, bmWidthBytes; public ushort bmPlanes, bmBitsPixel; public IntPtr bmBits; }

    [StructLayout(LayoutKind.Sequential)]
    struct BITMAPINFO
    {
        public int biSize, biWidth, biHeight; public short biPlanes, biBitCount;
        public int biCompression, biSizeImage, biXPelsPerMeter, biYPelsPerMeter, biClrUsed, biClrImportant;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 256)] public int[] colors; // room for a colour table
    }

    [DllImport("user32.dll")] static extern IntPtr LoadCursor(IntPtr hInst, IntPtr id);
    [DllImport("user32.dll")] static extern bool GetIconInfo(IntPtr h, out ICONINFO info);
    [DllImport("user32.dll")] static extern IntPtr CreateIconIndirect(ref ICONINFO info);
    [DllImport("user32.dll")] static extern bool SetSystemCursor(IntPtr h, uint id);
    [DllImport("user32.dll")] static extern bool SystemParametersInfo(uint action, uint param, IntPtr pv, uint flags);
    [DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr h);
    [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr h, IntPtr dc);
    [DllImport("gdi32.dll")] static extern int GetObject(IntPtr h, int size, out BITMAP bm);
    [DllImport("gdi32.dll")] static extern int GetDIBits(IntPtr dc, IntPtr bmp, uint start, uint lines, [Out] byte[] bits, ref BITMAPINFO bi, uint usage);
    [DllImport("gdi32.dll")] static extern IntPtr CreateBitmap(int w, int h, uint planes, uint bpp, byte[] bits);
    [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr h);

    const uint SPI_SETCURSORS = 0x57;

    // Arrow, I-beam, wait, cross, up, 4 resize, move, no, hand, app-starting, help, pin, person
    static readonly uint[] CursorIds = { 32512, 32513, 32514, 32515, 32516, 32642, 32643, 32644, 32645, 32646, 32648, 32649, 32650, 32651, 32671, 32672 };

    static byte[] ReadBits(IntPtr dc, IntPtr bmp, int w, int h)
    {
        var bi = new BITMAPINFO { biSize = 40, biWidth = w, biHeight = -h, biPlanes = 1, biBitCount = 32, colors = new int[256] };
        var bits = new byte[w * h * 4];
        GetDIBits(dc, bmp, 0, (uint)h, bits, ref bi, 0);
        return bits;
    }

    // Build a red version of a cursor: brightness -> red channel, keep shape/alpha/hotspot.
    static IntPtr MakeRed(IntPtr src)
    {
        ICONINFO ii;
        if (!GetIconInfo(src, out ii)) return IntPtr.Zero;
        BITMAP bm;
        GetObject(ii.hbmMask, Marshal.SizeOf(typeof(BITMAP)), out bm);
        bool mono = ii.hbmColor == IntPtr.Zero;
        int w = bm.bmWidth, h = mono ? bm.bmHeight / 2 : bm.bmHeight;

        IntPtr dc = GetDC(IntPtr.Zero);
        byte[] mask = ReadBits(dc, ii.hbmMask, w, mono ? h * 2 : h);
        byte[] color = mono ? null : ReadBits(dc, ii.hbmColor, w, h);
        ReleaseDC(IntPtr.Zero, dc);

        bool hasAlpha = false;
        if (!mono) for (int i = 3; i < color.Length; i += 4) if (color[i] != 0) { hasAlpha = true; break; }

        var px = new byte[w * h * 4];
        int maskStride = ((w + 15) / 16) * 2;
        var andBits = new byte[maskStride * h];

        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int p = (y * w + x) * 4;
                bool andBit = mask[p] != 0;
                int lum, a;
                if (mono)
                {
                    bool xorBit = mask[((y + h) * w + x) * 4] != 0;
                    if (andBit && !xorBit) { lum = 0; a = 0; }        // transparent
                    else if (!andBit && !xorBit) { lum = 0; a = 255; } // black
                    else { lum = 255; a = 255; }                       // white or invert -> red
                }
                else
                {
                    lum = (int)(0.299 * color[p + 2] + 0.587 * color[p + 1] + 0.114 * color[p]);
                    if (hasAlpha) a = color[p + 3];
                    else if (!andBit) a = 255;
                    else if (lum > 0) { a = 255; lum = 255; }          // old-style invert pixel
                    else a = 0;
                }
                px[p + 2] = (byte)lum;
                px[p + 3] = (byte)a;
                if (a == 0) andBits[y * maskStride + x / 8] |= (byte)(0x80 >> (x % 8));
            }

        var ni = new ICONINFO { fIcon = false, xHotspot = ii.xHotspot, yHotspot = ii.yHotspot };
        ni.hbmMask = CreateBitmap(w, h, 1, 1, andBits);
        ni.hbmColor = CreateBitmap(w, h, 1, 32, px);
        IntPtr cur = CreateIconIndirect(ref ni);

        DeleteObject(ni.hbmMask); DeleteObject(ni.hbmColor);
        DeleteObject(ii.hbmMask); if (!mono) DeleteObject(ii.hbmColor);
        return cur;
    }

    static void RedCursors()
    {
        foreach (uint id in CursorIds)
        {
            IntPtr src = LoadCursor(IntPtr.Zero, (IntPtr)id);
            if (src == IntPtr.Zero) continue;
            IntPtr red = MakeRed(src);
            if (red != IntPtr.Zero) SetSystemCursor(red, id); // Windows takes ownership of 'red'
        }
    }

    static void RestoreCursors() { SystemParametersInfo(SPI_SETCURSORS, 0, IntPtr.Zero, 0); }

    [STAThread]
    static void Main()
    {
        bool isFirst;
        var quit = new EventWaitHandle(false, EventResetMode.AutoReset, @"Local\RedModeQuit", out isFirst);
        if (!isFirst) { quit.Set(); return; }   // already running -> tell it to turn off

        if (!MagInitialize()) { MessageBox.Show("Could not start the screen filter.", "Red Mode"); return; }

        // Output red = perceived brightness of the original pixel; green and blue = 0.
        float[] m = {
            0.299f, 0, 0, 0, 0,
            0.587f, 0, 0, 0, 0,
            0.114f, 0, 0, 0, 0,
            0,      0, 0, 1, 0,
            0,      0, 0, 0, 1
        };
        if (!MagSetFullscreenColorEffect(m)) { MessageBox.Show("Could not apply the red filter.", "Red Mode"); MagUninitialize(); return; }

        try { RedCursors(); } catch { /* screen stays red even if pointers can't be changed */ }

        quit.WaitOne();

        RestoreCursors();
        MagUninitialize();
    }
}
