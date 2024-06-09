//
//  mtl_engine.mm
//  MetalTutorial
//

#include "mtl_engine.hpp"
#include "mtlm.h"
void MTLEngine::init() {
    initDevice();
    initWindow();
    
    createSquare();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
}
float rotationAngle = 0.0f;
void MTLEngine::run() {
    while (!glfwWindowShouldClose(glfwWindow)) {
        @autoreleasepool {
            metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
            draw();
            rotationAngle += 0.01f;
        }
        glfwPollEvents();
    }
}

void MTLEngine::cleanup() {
    glfwTerminate();
    metalDevice->release();
    delete grassTexture;
}

void MTLEngine::initDevice() {
    metalDevice = MTL::CreateSystemDefaultDevice();
}

void MTLEngine::frameBufferSizeCallback(GLFWwindow *window, int width, int height) {
    MTLEngine* engine = (MTLEngine*)glfwGetWindowUserPointer(window);
    engine->resizeFrameBuffer(width, height);
}

void MTLEngine::resizeFrameBuffer(int width, int height) {
    metalLayer.drawableSize = CGSizeMake(width, height);
}

void MTLEngine::initWindow() {
    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindow = glfwCreateWindow(800, 600, "Metal Engine", NULL, NULL);
    
    if (!glfwWindow) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    
    glfwSetWindowUserPointer(glfwWindow, this);
    glfwSetFramebufferSizeCallback(glfwWindow, frameBufferSizeCallback);
    int width, height;
    glfwGetFramebufferSize(glfwWindow, &width, &height);
    
    metalWindow = glfwGetCocoaWindow(glfwWindow);
    metalLayer = [CAMetalLayer layer];
    metalLayer.device = (__bridge id<MTLDevice>)metalDevice;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.drawableSize = CGSizeMake(width, height);
    metalWindow.contentView.layer = metalLayer;
    metalWindow.contentView.wantsLayer = YES;
}

void MTLEngine::createSquare() {
    VertexData squareVertices[] {
        {{-0.5, -0.5,  0.5, 1.0f}, {0.0f, 0.0f}},
        {{-0.5,  0.5,  0.5, 1.0f}, {0.0f, 1.0f}},
        {{ 0.5,  0.5,  0.5, 1.0f}, {1.0f, 1.0f}},
        {{-0.5, -0.5,  0.5, 1.0f}, {0.0f, 0.0f}},
        {{ 0.5,  0.5,  0.5, 1.0f}, {1.0f, 1.0f}},
        {{ 0.5, -0.5,  0.5, 1.0f}, {1.0f, 0.0f}}
    };
    
    squareVertexBuffer = metalDevice->newBuffer(&squareVertices, sizeof(squareVertices), MTL::ResourceStorageModeShared);

    // Make sure to change working directory to Metal-Tutorial root
    // directory via Product -> Scheme -> Edit Scheme -> Run -> Options
    grassTexture = new Texture("assets/mc_grass.jpeg", metalDevice);
}

void MTLEngine::createDefaultLibrary() {
    metalDefaultLibrary = metalDevice->newDefaultLibrary();
    if(!metalDefaultLibrary){
        std::cerr << "Failed to load default library.";
        std::exit(-1);
    }
}

void MTLEngine::createCommandQueue() {
    metalCommandQueue = metalDevice->newCommandQueue();
}

void MTLEngine::createRenderPipeline() {
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader);
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
        
    NS::Error* error;
    metalRenderPSO = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    renderPipelineDescriptor->release();
}

void MTLEngine::draw() {
    sendRenderCommand();
}
float t = 0.0f;
void MTLEngine::sendRenderCommand() {
    metalCommandBuffer = metalCommandQueue->commandBuffer();
    
    MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    MTL::RenderPassColorAttachmentDescriptor* cd = renderPassDescriptor->colorAttachments()->object(0);
    
    cd->setTexture(metalDrawable->texture());
    cd->setLoadAction(MTL::LoadActionClear);
    cd->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
    cd->setStoreAction(MTL::StoreActionStore);
    
    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    renderCommandEncoder->endEncoding();

    metalCommandBuffer->presentDrawable(metalDrawable);
    metalCommandBuffer->commit();
    metalCommandBuffer->waitUntilCompleted();
    
    renderPassDescriptor->release();
}
//-------------original----------------
//void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
//    simd::float4x4 transform = mtlm::identity();
//    renderCommandEncoder->setVertexBytes(&transform, sizeof(simd::float4x4), 1);
//    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
//    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);
//    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
//    NS::UInteger vertexStart = 0;
//    NS::UInteger vertexCount = 6;
//    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);
//    //----------------added------------------
////    transform = mtlm::z_rotation(0.0f);
////    renderCommandEncoder->setVertexBytes(&transform, sizeof(simd::float4x4), 1);
////    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);
//
//    //------------------
//    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
//}

//--------rotation of photo--------------------------------
//void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
//    // Define and set your transformation matrix
//    simd::float4x4 transform = mtlm::z_rotation(0.0f);
//    renderCommandEncoder->setVertexBytes(&transform, sizeof(simd::float4x4), 1);
//
//    // Set the render pipeline state and vertex buffer
//    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
//    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);
//
//    // Set the texture
//    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);
//
//    // Draw your primitives
//    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
//    NS::UInteger vertexStart = 0;
//    NS::UInteger vertexCount = 6;
//    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
//}


//----------------rotation throughout-------------------
/*
void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    // Define and set your transformation matrix with the updated rotation angle
    t += 1.0f;
    if (t > 360) {
        t -= 360.0f;
    }
    simd::float4x4 transform = mtlm::z_rotation(t);
    renderCommandEncoder->setVertexBytes(&transform, sizeof(simd::float4x4), 1);

    // Set the render pipeline state and vertex buffer
    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);

    // Set the texture
    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);

    // Draw your primitives
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 6;
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
}
*/
//-------------zoom and rotation-------------------------
/*
float zoom = 0.0f;
void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    // Define and set your transformation matrix with the updated zoom factor
    zoom += 0.01f; // Adjust the zoom factor as needed
    simd::float4x4 transform = mtlm::scale(zoom);

    renderCommandEncoder->setVertexBytes(&transform, sizeof(simd::float4x4), 1);

    // Set the render pipeline state and vertex buffer
    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);

    // Set the texture
    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);

    // Draw your primitives
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 6;
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
}
*/
//-------------------only zoom-------------------

float zoom = 0.0f;
void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    zoom += 0.01f; // yaha adjusting the zoom factor as needed for a slower zoom speed
 
    simd::float4x4 transform = mtlm::scale(zoom);

    renderCommandEncoder->setVertexBytes(&transform, sizeof(simd::float4x4), 1);

    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);

    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 6;
    
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
    
}


//-----------zoom with cursor-------------------
/*
float cursorX = 0.0f;
float cursorY = 0.0f;
float initialZoom=1.0f;
void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    
    float centerX = 1.0f;
    float centerY = 0.0f;
    float dx = cursorX - centerX;
    float dy = cursorY - centerY;
    float distance = sqrt(dx * dx + dy * dy);
    float zoomFactor = 1.0f - distance * 0.001f;
    float zoomed = initialZoom * zoomFactor;
    simd::float4x4 transform = mtlm::scale(zoomed);

    renderCommandEncoder->setVertexBytes(&transform, sizeof(simd::float4x4), 1);

    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);

    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 6;
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
}

*/


//set transformation before setVertex 
