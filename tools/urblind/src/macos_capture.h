#pragma once

#ifdef __APPLE__

#ifdef __cplusplus
extern "C" {
#endif

// C-compatible wrapper for macOS screen capture
// Returns raw RGBA8888 pixel data. Caller must free() it.
typedef struct {
    unsigned char* data;
    int width;
    int height;
} MacOSScreenCapture;

MacOSScreenCapture capture_screen_macos(int x, int y, int width, int height);

int get_mouse_position_macos(int* x, int* y);

#ifdef __cplusplus
}
#endif

#endif // __APPLE__
