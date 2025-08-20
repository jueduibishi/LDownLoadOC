//
//  ResumedataFile.h
//  LDownLoadOC
//
//  Created by l on 2025/4/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// resumeData管理，用于断点续传
@interface ResumedataFile : NSObject


/// 删除resumeData
/// - Parameter url: url
+ (BOOL)deleteResumeDataWithUrl:(NSString *)url;


/// 保存resumeData
/// - Parameters:
///   - resumeData: data
///   - url: url
+ (void)saveResumeData:(NSData *)resumeData withUrl:(NSString *)url;


/// 断点缓存
/// - Parameter url: url
+(nullable NSData*)resumeData:(NSString*)url;

@end

NS_ASSUME_NONNULL_END
