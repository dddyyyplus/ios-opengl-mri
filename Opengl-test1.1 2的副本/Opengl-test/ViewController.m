//
//  ViewController.m
//  Opengl-test
//
//  Created by GWJ on 2022/4/20.
//

#import "ViewController.h"


#define kCoodinateCount    26082
#define role [NSArray arrayWithObjects:@"a",@"b",@"c",@"[:hello]", nil]

typedef struct {
    GLKVector3 positionCoodinate; // 顶点坐标
    GLKVector3 colorCoodinate; // 顶点颜色
} MyVertex;



@interface ViewController () <GLKViewDelegate> {
    GLuint _bufferID;
    
    float ROC_X,ROC_Y,ROC_Z;
    float RX,RY,RZ;   //旋转
    float PX,PY;      //平移
    float S_XYZ;      //缩放
    long int count;
}
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
//@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;
@property (nonatomic, assign) MyVertex *vetrexs;
@property (nonatomic, assign) GLuint *indices;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger angle;
@property (nonatomic, assign) NSInteger player_num;
@property (nonatomic, assign) NSString *player_name;
@property (nonatomic, strong) UIPanGestureRecognizer *_panGesture;      //旋转
@property (nonatomic, strong) UIPinchGestureRecognizer *_pinchGesture;  //缩放
@property (nonatomic, strong) UIRotationGestureRecognizer *_rotationGesture; //旋转
@property (nonatomic, assign) BOOL IsPlay;

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *last;
@property (weak, nonatomic) IBOutlet UIButton *next;
@property (weak, nonatomic) IBOutlet UIButton *play;
@property (weak, nonatomic) IBOutlet UIButton *player;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController



- (void)dealloc{
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    if (self.vetrexs) {
        free(self.vetrexs);
        self.vetrexs = nil;
    }
    
    if (_bufferID) {
        glDeleteBuffers(1, &_bufferID);
        _bufferID = 0;
        
    }
    [self.displayLink invalidate];
}
- (void)cleanup{
    
    if (self.vetrexs) {
        free(self.vetrexs);
        self.vetrexs = nil;
    }
    
    if (_bufferID) {
        glDeleteBuffers(1, &_bufferID);
        _bufferID = 0;
    }
}
- (BOOL)shouldAutorotate {
    return NO;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    [self setupConfig];
    [self setupVertexData];
    [self setupIndicesData];
    [self setupTexture];
    [self setupGestures];
    [self addDisplayLink];
    
    //添加拖动条
    [self.view addSubview:self.slider];
    [self.view addSubview:self.last];
    [self.view addSubview:self.next];
    [self.view addSubview:self.play];
    [self.view addSubview:self.player];
    [self.view addSubview:self.label];
    //[self.view addSubview:self.dustin_johnson];
    //[self.view addSubview:self.justin_rose];
    //[self.view addSubview:self.mike_weir];
    //[self.view addSubview:self.natalie_gulbis];
    
}
// 手势配置
- (void) setupGestures{
    ROC_X = 0.23f; ROC_Y = 0.38f; ROC_Z = -0.29f;
    RX = 0; RY = 0; RZ = 0;
    PX = 0; PY = 0;
    S_XYZ = 1;
    self.IsPlay = YES;
    self.view.backgroundColor = [UIColor orangeColor];
    
    self._panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(viewRotation:)];
    [self.view addGestureRecognizer:self._panGesture];
    
    self._pinchGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(viewZoom:)];
    [self.view addGestureRecognizer:self._pinchGesture];
}
// 配置基本信息
- (void)setupConfig{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
   
    
    // 判断是否创建成功
    if (!self.context) {
        NSLog(@"Create ES context failed");
        return;
    }
    
    // 设置当前上下文
    [EAGLContext setCurrentContext:self.context];
    
    // GLKView
    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height );
    self.glkView = [[GLKView alloc] initWithFrame:frame context:self.context];
    self.glkView.delegate = self;
    self.glkView.context = self.context;
    
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    [self.view addSubview:self.glkView];
    
    glClearColor(0.76f, 0.76f,0.76f, 1);
}

// 配置顶点数据
- (void)setupVertexData{
    // 开辟空间
    [self cleanup];
    self.vetrexs = malloc(sizeof(MyVertex) * kCoodinateCount);
    //NSString *str1 = [@"player/"stringByAppendingString: @"dustin_johnson"];
    if (self.player_name == NULL){
        self.player_name =@"dustin_johnson";
    }
    NSString *str1 = [@"player/"stringByAppendingString: self.player_name];
    NSString *str2 = [str1 stringByAppendingString:@"/output/"];
    NSLog(@"1233444%@",str2);
    NSString *str = [[NSBundle mainBundle] pathForResource:[str2 stringByAppendingString: [NSString stringWithFormat:@"%ld",(long)self.angle]]ofType:@"txt"];

        NSLog(@"q%@",str);
    //NSURL *url = [NSURL URLWithString:@"/Users/gwj/Desktop/oc-test/Opengl-test/Opengl-test/bin/output/0.txt"];
    NSString *connect = [[NSString alloc] initWithContentsOfFile: str encoding:NSUTF8StringEncoding error:nil];
    NSCharacterSet *character = [NSCharacterSet whitespaceCharacterSet];
    NSArray *array = [connect componentsSeparatedByCharactersInSet:character];
    NSLog(@"count:%lu",(unsigned long)array.count);
    for(int i= 1,j=0;i<array.count-1;i+=3,j++){
        self.vetrexs[j] = (MyVertex){{[array[i] floatValue]/100, [array[i+1] floatValue]/100, [array[i+2] floatValue]/100},{0.0f,1.0f,0.0f}};
    }
   
    glGenBuffers(1, &_bufferID); // 开辟1个顶点缓冲区，所以传入1
    NSLog(@"bufferID:%d", _bufferID);
    // 绑定顶点缓冲区
    glBindBuffer(GL_ARRAY_BUFFER, _bufferID);
    // 缓冲区大小
    GLsizeiptr bufferSizeBytes = sizeof(MyVertex) * kCoodinateCount;
    // 将顶点数组的数据copy到顶点缓冲区中(GPU显存中)
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vetrexs, GL_STREAM_DRAW);
    
    
    // 打开读取通道
    glEnableVertexAttribArray(GLKVertexAttribPosition); // 顶点坐标数据
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(MyVertex)/*由于是结构体，所以步长就是结构体大小*/, NULL + offsetof(MyVertex, positionCoodinate));
    
    //顶点颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(MyVertex)/*由于是结构体，所以步长就是结构体大小*/,NULL + offsetof(MyVertex, colorCoodinate));

}
-(void)setupIndicesData{
    if (self.player_name == NULL){
        self.player_name =@"dustin_johnson";
    }
    NSString *str1 = [@"player/"stringByAppendingString: self.player_name];
    NSString *str2 = [str1 stringByAppendingString:@"/count/count"];
    NSString *count_path = [[NSBundle mainBundle] pathForResource:str2 ofType:@"txt"];
    NSLog(@"str2%@",str2);
    NSString *count_content = [[NSString alloc] initWithContentsOfFile:count_path encoding:NSUTF8StringEncoding error:nil];
    NSCharacterSet *character = [NSCharacterSet whitespaceCharacterSet];
    NSArray *count_array = [count_content componentsSeparatedByCharactersInSet:character];
    self.indices = malloc(sizeof(GLuint) * count_array.count);
    count =count_array.count;
    for(int i=0;i<count_array.count;i++){
        self.indices[i] = [count_array[i] intValue];
        NSLog(@"%d",self.indices[i]);
    }
//    NSNumber *sum = [count_array valueForKeyPath:@"@sum.floatValue"];
//
//    NSLog(@"aaa%@",sum);
        
        
    //1.绘图索引
//    GLuint indices[] = {
//        0, 3, 2,
//        0, 1, 3,
//        0, 2, 4,
//        0, 4, 1,
//        2, 3, 4,
//        1, 4, 3,
//    };
    //顶点个数
    //self.count = sizeof(indices) /sizeof(GLuint);
    //将索引数组存储到索引缓冲区 GL_ELEMENT_ARRAY_BUFFER
//    GLuint index;
//    glGenBuffers(1, &index);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}

// 配置纹理
- (void)setupTexture{
    //NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"png"];
    
    // 初始化纹理
   // NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft: @(1)}; // 纹理坐标原点是左下角,但是图片显示原点应该是左上角
    //GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    //NSLog(@"textureInfo.name: %d", textureInfo.name);
    
    // 使用苹果`GLKit`提供的`GLKBaseEffect`完成着色器工作(顶点/片元)
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.colorMaterialEnabled = GL_TRUE;
//    self.baseEffect.texture2d0.enabled = GL_TRUE;
//    //self.baseEffect.texture2d0.name = textureInfo.name;
//    //self.baseEffect.texture2d0.target = textureInfo.target;
    self.baseEffect.light0.enabled = YES; // 开启光照效果
    self.baseEffect.light0.specularColor = GLKVector4Make(1.0f, 0.0f,0.0f, 1);
    self.baseEffect.light0.ambientColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0);
    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0);// 开启漫反射
    self.baseEffect.light0.position = GLKVector4Make(0, 10.0f, 0, 1); // 光源位置
    
//
    // 透视投影矩阵
//    CGFloat aspect = fabs(self.glkView.bounds.size.width / self.glkView.bounds.size.height);
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0),aspect,0.2f, 0.5f);
//    self.baseEffect.transform.projectionMatrix = projectionMatrix;
    //正交投影矩阵
//    GLKMatrix4 orthoMatrix = GLKMatrix4MakeOrtho(-4.0f, 4.0f, -4.0f, 4.0f, -4.0f, 4.0f);
//    self.baseEffect.transform.projectionMatrix = orthoMatrix;
}

// 添加定时器
- (void)addDisplayLink{
    self.angle = 0;
    self.player_num = 0;
    self.player_name = @"dustin_johnson";
    _label.text = self.player_name;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateScene)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

// 更新
- (void)updateScene{
    // 角度变化
    if(self.IsPlay){
        self.angle = (self.angle+1)%150;
    }
    self.slider.value=self.angle;
    //self.angle=1;
    [self setupVertexData];
    //self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.3, 1, 0.7);
    // 修改`baseEffect.transform.modelviewMatrix`
    //GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, -4.0);
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, ROC_X, ROC_Y, ROC_Z);//旋转点0.23f, 0.38f, -0.29f 先平移 再旋转 再平移
    //旋转
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, -0.23f, -0.38f, 0.0f);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, RX);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, RY);
    modelViewMatrix =GLKMatrix4Translate(modelViewMatrix, PX, 0, 0);
    modelViewMatrix =GLKMatrix4Translate(modelViewMatrix, 0, PY, 0);
    
    //比例scale
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, S_XYZ, S_XYZ, S_XYZ);
    
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, -ROC_X, -ROC_Y, -ROC_Z);
    self.baseEffect.transform.modelviewMatrix = modelViewMatrix;
    
    
    // 重新渲染
    [self.glkView display];
}

#pragma mark GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    // 开启深度测试
    glEnable(GL_DEPTH_TEST);
    // 清除颜色缓冲区、深度缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // 准备绘制
    [self.baseEffect prepareToDraw];
    
    // 开始绘制
    //glDrawArrays(GL_TRIANGLES, 0, 3); // 从第一个开始，所以是0
    //glDrawArrays(GL_TRIANGLE_FAN, 4, 3);
    int start = 0;
    for(int i=0;i<count;i++){
        //glDrawArrays(GL_LINE_LOOP, start, [count_array[i] intValue]);
        glDrawArrays(GL_TRIANGLE_FAN, start, self.indices[i]);
        start += self.indices[i];
    }
   
}
#pragma mark Touch
-(void)viewRotation:(UIPanGestureRecognizer *)panGesture{
    if(panGesture.numberOfTouches==1){
        CGPoint transPoint = [panGesture translationInView:self.view];
        float x = transPoint.x/80;
        float y = transPoint.y/80 ;
        RX +=y;
        RY +=x;
        RZ +=0.0;
    }else if(panGesture.numberOfTouches == 3){
        CGPoint transPoint = [panGesture translationInView:self.view];
        float x = transPoint.x/200;
        float y = transPoint.y/200 ;
        PX +=x;
        PY +=-y;
        ROC_X+=x; ROC_Y -=y;
    }
    [self updateScene];
    [panGesture setTranslation:CGPointMake(0, 0) inView:self.view];
}
-(void)viewZoom:(UIPinchGestureRecognizer *)pinchGesture{
    float scale = pinchGesture.scale;
    
    S_XYZ *= scale;
    [self updateScene];
    pinchGesture.scale = 1.0;
}
#pragma mark Progress
/**
 * 懒加载拖动条
 */
- (UISlider *)slider {
    if (_slider != nil) {
        //设置最大值
        _slider.maximumValue = 150;
        //设置最小值，可以为负值
        _slider.minimumValue = 0;
        //设置滑块左侧背景颜色
        _slider.minimumTrackTintColor = [UIColor blueColor];
        //设置滑块右侧背景颜色
        _slider.maximumTrackTintColor = [UIColor greenColor];
        //设置滑块颜色
        _slider.thumbTintColor = [UIColor orangeColor];
        //设置滑动条滑动事件回调
        [_slider addTarget:self action:@selector(pressSlider:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}
- (void) pressSlider:(UISlider*) slider {
    //滑动条和进度同步进度
    self.angle = (int)slider.value;
   
}
- (IBAction)playTouch {
        if(_IsPlay){
            _IsPlay = NO;
            _play.titleLabel.text=@"Play";
        }else{
            _IsPlay=YES;
            _play.titleLabel.text=@"Pause";
        }
    
}
- (IBAction)lastTouch {
    _angle--;
    _angle%=217;
}
- (IBAction)nextTouch {
    _angle++;
    _angle%=217;
}
- (IBAction)player_change:(id)sender {
    
    //[_player setTitle:@"Add Stuff" forState: UIControlStateNormal];
    
    self.player_num = (self.player_num + 1) % 4;
    switch (self.player_num) {
        case 0:
            self.player_name = @"dustin_johnson";
            break;
        case 1:
            self.player_name = @"justin_rose";
            break;
        case 2:
            self.player_name = @"mike_weir";
            break;
        case 3:
            self.player_name = @"natalie_gulbis";
            break;
        default:
            break;
    }
    self.angle = 0;
    _label.text = self.player_name;
    RX = 0; RY = 0; RZ = 0;
    PX = 0; PY = 0;
    S_XYZ = 1;
    [self setupIndicesData];
    [self.glkView display];
}



@end
