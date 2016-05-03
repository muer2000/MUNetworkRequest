//
//  MUNetworkRequest.h
//  MURequest
//
//  Created by Muer on 16/4/19.
//  Copyright © 2016年 Muer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@class MUNetworkRequest;

typedef void(^MUNetworkRequestSuccessBlock)(MUNetworkRequest *request, id responseObject);
typedef void(^MUNetworkRequestFailureBlock)(MUNetworkRequest *request, NSError *error);
typedef void(^MUNetworkRequestProgressBlock)(double progress);

@interface MUNetworkRequest : NSObject

// POST Request
+ (instancetype)postRequest:(NSString *)URLString
                 parameters:(NSDictionary *)parameters
                    success:(MUNetworkRequestSuccessBlock)successBlock
                    failure:(MUNetworkRequestFailureBlock)failureBlock;

+ (instancetype)postRequest:(NSString *)URLString
                 parameters:(NSDictionary *)parameters
                    success:(MUNetworkRequestSuccessBlock)successBlock
                    failure:(MUNetworkRequestFailureBlock)failureBlock
           downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock;

+ (instancetype)postRequest:(NSString *)URLString
                 parameters:(NSDictionary *)parameters
                    success:(MUNetworkRequestSuccessBlock)successBlock
                    failure:(MUNetworkRequestFailureBlock)failureBlock
           downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock
                   formData:(void (^)(id <AFMultipartFormData> formData))formDataBlock
             uploadProgress:(MUNetworkRequestProgressBlock)uploadProgressblock;

// GET Request
+ (instancetype)getRequest:(NSString *)URLString
                parameters:(NSDictionary *)parameters
                   success:(MUNetworkRequestSuccessBlock)successBlock
                   failure:(MUNetworkRequestFailureBlock)failureBlock;

+ (instancetype)getRequest:(NSString *)URLString
                parameters:(NSDictionary *)parameters
                   success:(MUNetworkRequestSuccessBlock)successBlock
                   failure:(MUNetworkRequestFailureBlock)failureBlock
          downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock;

// Request with method
+ (instancetype)requestWithMethod:(NSString *)method
                        URLString:(NSString *)URLString
                       parameters:(NSDictionary *)parameters
                          success:(MUNetworkRequestSuccessBlock)successBlock
                          failure:(MUNetworkRequestFailureBlock)failureBlock
                 downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock
                         formData:(void (^)(id <AFMultipartFormData> formData))formDataBlock
                   uploadProgress:(MUNetworkRequestProgressBlock)uploadProgressblock;

@property (nonatomic, strong) NSDictionary *userInfo;

// Session task
@property (nonatomic, readonly) NSURLSessionTask *sessionTask;

// Response
@property (nonatomic, readonly) NSData *responseData;
@property (nonatomic, readonly) id responseJSONObject;
@property (nonatomic, readonly) NSString *responseString;


// Request control
+ (void)cancelAllRequest;
+ (void)cancelRequestWithPath:(NSString *)path;

- (void)cancel;


// Base URL
+ (NSURL *)baseURL;
+ (void)setBaseURL:(NSURL *)baseURL;

// ignore cancel error callback. default value is YES
+ (BOOL)ignoreCancelError;
+ (void)setIgnoreCancelError:(BOOL)ignoreCancelError;

@end
