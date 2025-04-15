//
//  ResumedataFile.h
//  LDownLoadOC
//
//  Created by l on 2025/4/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// resumeData管理
@interface ResumedataFile : NSObject

/// 主目录
+ (NSString *)mainCategory;


/// 删除resumeData
/// - Parameter url: url
+ (BOOL)deleteResumeDataWithUrl:(NSString *)url;


/// 保存resumeData
/// - Parameters:
///   - resumeData: data
///   - url: url
+ (void)saveResumeData:(NSData *)resumeData withUrl:(NSString *)url;


/// 获取加密后的文件名
/// - Parameter url: url
+(NSString*)fileName:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
