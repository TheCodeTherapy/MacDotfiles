#ifdef __APPLE__

#import <Foundation/Foundation.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include "macos_capture.h"
#include <iostream>

MacOSScreenCapture capture_screen_macos(void) {
    MacOSScreenCapture result = {nullptr, 0, 0};
    
    // ScreenCaptureKit requires macOS 12.3+
    if (@available(macOS 12.3, *)) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block CGImageRef capturedImage = nullptr;
        
        // Get shareable content
        [SCShareableContent getShareableContentWithCompletionHandler:^(SCShareableContent *content, NSError *error) {
            if (error) {
                std::cerr << "Failed to get shareable content: " << error.localizedDescription.UTF8String << std::endl;
                dispatch_semaphore_signal(semaphore);
                return;
            }
            
            if (content.displays.count == 0) {
                std::cerr << "No displays found!" << std::endl;
                dispatch_semaphore_signal(semaphore);
                return;
            }
            
            // Capture all displays
            SCContentFilter *filter = [[SCContentFilter alloc] initWithDisplay:content.displays.firstObject
                                                               excludingWindows:@[]];
            
            SCStreamConfiguration *config = [[SCStreamConfiguration alloc] init];
            config.width = content.displays.firstObject.width;
            config.height = content.displays.firstObject.height;
            config.pixelFormat = kCVPixelFormatType_32BGRA;
            config.showsCursor = NO;
            
            // Capture single frame
            [SCScreenshotManager captureImageWithFilter:filter
                                          configuration:config
                                      completionHandler:^(CGImageRef image, NSError *error) {
                if (error) {
                    std::cerr << "Failed to capture screen: " << error.localizedDescription.UTF8String << std::endl;
                } else if (image) {
                    capturedImage = CGImageRetain(image);
                }
                dispatch_semaphore_signal(semaphore);
            }];
        }];
        
        // Wait for capture to complete (with 5 second timeout)
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(semaphore, timeout) == 0 && capturedImage) {
            // Convert CGImage to RGBA8888
            size_t width = CGImageGetWidth(capturedImage);
            size_t height = CGImageGetHeight(capturedImage);
            size_t dataSize = width * height * 4;
            
            unsigned char* rgbaData = (unsigned char*)malloc(dataSize);
            if (rgbaData) {
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef context = CGBitmapContextCreate(
                    rgbaData,
                    width,
                    height,
                    8,
                    width * 4,
                    colorSpace,
                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big
                );
                
                if (context) {
                    CGContextDrawImage(context, CGRectMake(0, 0, width, height), capturedImage);
                    CGContextRelease(context);
                    
                    result.data = rgbaData;
                    result.width = (int)width;
                    result.height = (int)height;
                    
                    std::cout << "Captured screen: " << width << "x" << height << std::endl;
                } else {
                    free(rgbaData);
                    std::cerr << "Failed to create bitmap context!" << std::endl;
                }
                
                CGColorSpaceRelease(colorSpace);
            }
            
            CGImageRelease(capturedImage);
        } else {
            std::cerr << "Screen capture timed out!" << std::endl;
        }
    } else {
        std::cerr << "ScreenCaptureKit requires macOS 12.3 or later!" << std::endl;
    }
    
    return result;
}

#endif // __APPLE__
