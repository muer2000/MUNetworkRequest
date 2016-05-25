//
//  MUNetworkRequest.m
//  MURequest
//
//  Created by Muer on 16/4/19.
//  Copyright © 2016年 Muer. All rights reserved.
//

#import "MUNetworkRequest.h"

static NSString * const kHTTPMethodGET = @"GET";
static NSString * const kHTTPMethodPOST = @"POST";

static NSString * const kSessionStateKey = @"state";
static NSString * const kSessionCountOfBytesSentKey = @"countOfBytesSent";
static NSString * const kSessionCountOfBytesReceivedKey = @"countOfBytesReceived";

static NSString * const kResponseInfoDataKey = @"ResponseInfoDataKey";
static NSString * const kResponseInfoJSONObjectKey = @"ResponseInfoJSONObjectKey";


static void * MUTaskCountOfBytesSentContext = &MUTaskCountOfBytesSentContext;
static void * MUTaskCountOfBytesReceivedContext = &MUTaskCountOfBytesReceivedContext;

typedef void(^MUSessionTaskSuccessBlock)(NSURLSessionDataTask *task, id responseObject);
typedef void(^MUSessionTaskFailureBlock)(NSURLSessionDataTask *task, NSError *error);

static NSURL *kSharedBaseURL = nil;
static BOOL kSharedIgnoreCancelError = YES;


@interface MUResponseSerializer : AFJSONResponseSerializer

@end


@interface MUNetworkRequest ()

@property (nonatomic, copy) NSString *responseString;

@property (nonatomic, weak) NSURLSessionTask *sessionTask;
@property (nonatomic, strong) NSDictionary *responseInfo;

@property (nonatomic, copy) MUNetworkRequestProgressBlock downloadProgressBlock;
@property (nonatomic, copy) MUNetworkRequestProgressBlock uploadProgressBlock;

@end

@implementation MUNetworkRequest

+ (AFHTTPSessionManager *)sharedSessionManager
{
    static AFHTTPSessionManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AFHTTPSessionManager alloc] initWithBaseURL:kSharedBaseURL];
        instance.responseSerializer = [MUResponseSerializer serializer];
    });
    return instance;
}

+ (instancetype)postRequest:(NSString *)URLString
                 parameters:(NSDictionary *)parameters
                    success:(MUNetworkRequestSuccessBlock)successBlock
                    failure:(MUNetworkRequestFailureBlock)failureBlock
{
    return [self postRequest:URLString parameters:parameters success:successBlock failure:failureBlock downloadProgress:nil];
}

+ (instancetype)postRequest:(NSString *)URLString
                 parameters:(NSDictionary *)parameters
                    success:(MUNetworkRequestSuccessBlock)successBlock
                    failure:(MUNetworkRequestFailureBlock)failureBlock
           downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock
{
    return [self postRequest:URLString parameters:parameters success:successBlock failure:failureBlock downloadProgress:nil formData:nil uploadProgress:nil];
}

+ (instancetype)postRequest:(NSString *)URLString
                 parameters:(NSDictionary *)parameters
                    success:(MUNetworkRequestSuccessBlock)successBlock
                    failure:(MUNetworkRequestFailureBlock)failureBlock
           downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock
                   formData:(void (^)(id <AFMultipartFormData> formData))formDataBlock
             uploadProgress:(MUNetworkRequestProgressBlock)uploadProgressblock
{
    return [self requestWithMethod:kHTTPMethodPOST URLString:URLString parameters:parameters success:successBlock failure:failureBlock downloadProgress:downloadProgressBlock formData:formDataBlock uploadProgress:uploadProgressblock];
}

+ (instancetype)getRequest:(NSString *)URLString
                parameters:(NSDictionary *)parameters
                   success:(MUNetworkRequestSuccessBlock)successBlock
                   failure:(MUNetworkRequestFailureBlock)failureBlock
{
    return [self getRequest:URLString parameters:parameters success:successBlock failure:failureBlock downloadProgress:nil];
}

+ (instancetype)getRequest:(NSString *)URLString
                parameters:(NSDictionary *)parameters
                   success:(MUNetworkRequestSuccessBlock)successBlock
                   failure:(MUNetworkRequestFailureBlock)failureBlock
          downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock
{
    return [self requestWithMethod:kHTTPMethodGET URLString:URLString parameters:parameters success:successBlock failure:failureBlock downloadProgress:downloadProgressBlock formData:nil uploadProgress:nil];
}

+ (instancetype)requestWithMethod:(NSString *)method
                        URLString:(NSString *)URLString
                       parameters:(NSDictionary *)parameters
                          success:(MUNetworkRequestSuccessBlock)successBlock
                          failure:(MUNetworkRequestFailureBlock)failureBlock
                 downloadProgress:(MUNetworkRequestProgressBlock)downloadProgressBlock
                         formData:(void (^)(id <AFMultipartFormData> formData))formDataBlock
                   uploadProgress:(MUNetworkRequestProgressBlock)uploadProgressblock
{
    MUNetworkRequest *networkRequest = [[MUNetworkRequest alloc] init];

    MUSessionTaskSuccessBlock sessionSuccessBlock = ^(NSURLSessionDataTask *task, id responseObject){
        // responseObject is dictionary
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            networkRequest.responseInfo = responseObject;
        }
        if (successBlock) {
            successBlock(networkRequest, networkRequest.responseObject);
        }
    };

    MUSessionTaskFailureBlock sessionFailureBlock = ^(NSURLSessionDataTask *task, NSError *error){
        // ignore cancel error
        if (failureBlock && (![self ignoreCancelError] || error.code != NSURLErrorCancelled)) {
            failureBlock(networkRequest, error);
        }
    };
    
    // sessionTask
    AFHTTPSessionManager *manager = [MUNetworkRequest sharedSessionManager];
    NSURLSessionTask *sessionTask = nil;
    // GET/POST
    if ([method isEqualToString:kHTTPMethodGET]) {
        sessionTask = [manager GET:URLString parameters:parameters progress:nil success:sessionSuccessBlock failure:sessionFailureBlock];
    }
    else {
        // different implementations
        if (formDataBlock) {
            sessionTask = [manager POST:URLString parameters:parameters constructingBodyWithBlock:formDataBlock progress:nil success:sessionSuccessBlock failure:sessionFailureBlock];
        }
        else {
            sessionTask = [manager POST:URLString parameters:parameters progress:nil success:sessionSuccessBlock failure:sessionFailureBlock];
        }
    }
    networkRequest.sessionTask = sessionTask;
    
    // download block
    if (downloadProgressBlock) {
        networkRequest.downloadProgressBlock = downloadProgressBlock;
        [sessionTask addObserver:networkRequest forKeyPath:kSessionStateKey options:NSKeyValueObservingOptionNew context:MUTaskCountOfBytesReceivedContext];
        [sessionTask addObserver:networkRequest forKeyPath:kSessionCountOfBytesReceivedKey options:NSKeyValueObservingOptionNew context:MUTaskCountOfBytesReceivedContext];
    }
    // upload block
    if (uploadProgressblock) {
        networkRequest.uploadProgressBlock = uploadProgressblock;
        [sessionTask addObserver:networkRequest forKeyPath:kSessionStateKey options:NSKeyValueObservingOptionNew context:MUTaskCountOfBytesSentContext];
        [sessionTask addObserver:networkRequest forKeyPath:kSessionCountOfBytesSentKey options:NSKeyValueObservingOptionNew context:MUTaskCountOfBytesSentContext];
    }
    return networkRequest;
}


#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(__unused NSDictionary *)change
                       context:(void *)context
{
    if (context == MUTaskCountOfBytesSentContext || context == MUTaskCountOfBytesReceivedContext) {
        if ([keyPath isEqualToString:kSessionCountOfBytesSentKey]) {
            if ([object countOfBytesExpectedToSend] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.uploadProgressBlock) {
                        self.uploadProgressBlock([object countOfBytesSent] / ([object countOfBytesExpectedToSend] * 1.0f));
                    }
                });
            }
        }
        
        if ([keyPath isEqualToString:kSessionCountOfBytesReceivedKey]) {
            if ([object countOfBytesExpectedToReceive] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.downloadProgressBlock) {
                        self.downloadProgressBlock([object countOfBytesReceived] / ([object countOfBytesExpectedToReceive] * 1.0f));
                    }
                });
            }
        }
        
        if ([keyPath isEqualToString:kSessionStateKey] && [(NSURLSessionTask *)object state] == NSURLSessionTaskStateCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    if (self.uploadProgressBlock) {
                        self.uploadProgressBlock = nil;
                        [object removeObserver:self forKeyPath:kSessionStateKey];
                        [object removeObserver:self forKeyPath:kSessionCountOfBytesSentKey];
                    }
                    if (self.downloadProgressBlock) {
                        self.downloadProgressBlock = nil;
                        [object removeObserver:self forKeyPath:kSessionStateKey];
                        [object removeObserver:self forKeyPath:kSessionCountOfBytesReceivedKey];
                    }
                }
                @catch (NSException * __unused exception) {}
            });
        }
    }
}


#pragma mark - Response

- (NSData *)responseData
{
    return self.responseInfo[kResponseInfoDataKey];
}

- (id)responseObject
{
    return self.responseInfo[kResponseInfoJSONObjectKey];
}

- (NSString *)responseString
{
    if (!_responseString && self.responseData) {
        _responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    }
    return _responseString;
}


#pragma mark - Cancel

+ (void)cancelAllRequest
{
    [[[self sharedSessionManager] tasks] makeObjectsPerformSelector:@selector(cancel)];
}

+ (void)cancelRequestWithPath:(NSString *)path
{
    NSArray *tasks = [[self sharedSessionManager] tasks];
    for (NSURLSessionTask *task in tasks) {
        if ([[[[task currentRequest] URL] absoluteString] rangeOfString:path].location != NSNotFound) {
            [task cancel];
        }
    }
}

- (void)cancel
{
    [self.sessionTask cancel];
}


#pragma mark - Request options

+ (NSURL *)baseURL
{
    return kSharedBaseURL;
}

+ (void)setBaseURL:(NSURL *)baseURL
{
    kSharedBaseURL = baseURL;
}

+ (BOOL)ignoreCancelError
{
    return kSharedIgnoreCancelError;
}

+ (void)setIgnoreCancelError:(BOOL)ignoreCancelError
{
    kSharedIgnoreCancelError = ignoreCancelError;
}

@end


#pragma mark - MUResponseSerializer

@implementation MUResponseSerializer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    }
    return self;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (!data) {
        return nil;
    }
    id responseObject = [super responseObjectForResponse:response data:data error:error];
    if (responseObject) {
        return @{kResponseInfoJSONObjectKey: responseObject,
                 kResponseInfoDataKey: data};
    }
    return @{kResponseInfoDataKey: data};
}

@end